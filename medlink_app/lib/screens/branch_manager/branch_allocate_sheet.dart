import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';

/// Allocation modal — faithful to the approved design ("تفاصيل التخصيص"):
/// a smart engine with four real transfer strategies (two AI + two manual),
/// an editable items table with availability chips, a mandatory delivery
/// date that gates the confirm button, and the atomic `branch_allocate_order`
/// RPC (migration 0009) that deducts stock and issues the invoice.
///
/// Strategies (all wired to real data + real RPCs):
///   • نقل ذكي (الكل)          : auto-pulls every missing quantity from the
///                              branch that can supply it, then allocates 100%.
///   • نقل ذكي (المتأخرة فقط)  : same engine, enabled only for overdue orders
///                              (scheduled_delivery_at before today).
///   • نقل جزئي يدوي           : allocates min(required, available) per item.
///   • نقل كامل للمركز         : allocates 100% (blocked if stock is short).
class BranchAllocateSheet extends StatefulWidget {
  const BranchAllocateSheet({super.key, required this.order});

  final OrderModel order;

  @override
  State<BranchAllocateSheet> createState() => _BranchAllocateSheetState();
}

class _BranchAllocateSheetState extends State<BranchAllocateSheet> {
  final List<_RowState> _rows = [];
  DateTime? _deliveryDate;
  String? _error;
  bool _busy = false;

  /// An order counts as "overdue" when its expected delivery date fell before
  /// today (the date-only comparison matches the `date` column semantics).
  bool get _isOverdue {
    final s = widget.order.scheduledDeliveryAt;
    if (s == null) return false;
    final d = DateTime.tryParse(s);
    if (d == null) return false;
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day).isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  void initState() {
    super.initState();
    final stock = context.read<BranchController>().inventory;
    final availableByProduct = <String, int>{
      for (final item in stock) item.productId: item.quantity,
    };
    for (final item in widget.order.items ?? []) {
      if (item.isBonus) continue;
      final required = item.quantity;
      final available = availableByProduct[item.productId] ?? 0;
      _rows.add(_RowState(
        productId: item.productId,
        productName: item.product?.name ?? '—',
        required: required,
        available: available,
      ));
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    super.dispose();
  }

  List<String> get _missingProductIds =>
      _rows.where((r) => r.available < r.required).map((r) => r.productId).toList();

  bool get _hasInsufficientRows =>
      _rows.any((r) => (int.tryParse(r.controller.text.trim()) ?? 0) > r.available);

  bool get _canConfirm =>
      _deliveryDate != null &&
      !_hasInsufficientRows &&
      _rows.any((r) => (int.tryParse(r.controller.text.trim()) ?? 0) > 0);

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyPartial() {
    for (final r in _rows) {
      final value = r.available < r.required ? r.available : r.required;
      r.controller.text = '$value';
    }
    setState(() {});
  }

  void _applyFull() {
    for (final r in _rows) {
      r.controller.text = '${r.required}';
    }
    setState(() {});
  }

  /// Smart engine shared by the two AI options: pull every missing quantity
  /// from a branch that actually has it (via `branch_transfer_stock_between
  /// _branches`, migration 0010), then allocate 100%.
  Future<void> _smartTransfer() async {
    await _runBusy(() async {
      final branch = context.read<BranchController>();
      final missing = _missingProductIds;
      if (missing.isNotEmpty) {
        final suppliers = await branch.stockAcrossBranches(missing);
        for (final r in _rows) {
          if (r.available >= r.required) continue;
          final need = r.required - r.available;
          final candidates = suppliers.where(
              (s) => s['product_id'] == r.productId && (s['quantity'] as int) >= need);
          if (candidates.isEmpty) {
            throw Exception(
                'لا يوجد مخزون كافٍ لصنف "${r.productName}" في الفروع الأخرى');
          }
          final source = candidates.first;
          await branch.transferStock(
            productId: r.productId,
            toBranchId: source['branch_id'] as String,
            quantity: need,
          );
          r.available += need;
        }
      }
      for (final r in _rows) {
        r.controller.text = '${r.required}';
      }
      setState(() {});
    });
  }

  Future<void> _confirm() async {
    final allocations = <Map<String, dynamic>>[
      for (final r in _rows)
        if ((int.tryParse(r.controller.text.trim()) ?? 0) > 0)
          {
            'product_id': r.productId,
            'allocated_qty': int.tryParse(r.controller.text.trim()) ?? 0,
          },
    ];
    await _runBusy(() async {
      final branch = context.read<BranchController>();
      await branch.allocateOrder(
        orderId: widget.order.id,
        issueInvoice: true,
        expectedDeliveryDate: _deliveryDate,
        allocations: allocations,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد التخصيص وإصدار الفاتورة بنجاح')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clientName = widget.order.client?.name?.isNotEmpty == true
        ? widget.order.client!.name!
        : l10n.orderNumber;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: BranchColors.surfaceContainer,
              border: Border(
                bottom: BorderSide(color: BranchColors.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تفاصيل التخصيص',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'الطلب ${widget.order.id.substring(0, 8).toUpperCase()} • $clientName',
                        style: const TextStyle(
                            color: BranchColors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // AI Transfer Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BranchColors.primary.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BranchColors.primary.withValues(alpha: .20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: BranchColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('محرك التخصيص الذكي',
                              style: TextStyle(
                                  color: BranchColors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StrategyButton(
                              label: '🤖 نقل ذكي (الكل)',
                              hint: 'سحب تلقائي للمخزون المفقود من الفروع المتوفرة',
                              filled: true,
                              enabled: !_busy,
                              onTap: _smartTransfer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StrategyButton(
                              label: '🤖 نقل ذكي (المتأخرة فقط)',
                              hint: _isOverdue
                                  ? 'سحب تلقائي للمخزون المفقود (طلب متأخر)'
                                  : 'متاح للطلبات التي فات موعد تسليمها',
                              filled: false,
                              enabled: !_busy && _isOverdue,
                              onTap: _smartTransfer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Items table
                Text('الأصناف المطلوبة',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: BranchColors.outlineVariant),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        color: BranchColors.surfaceContainerLow,
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Text('اسم المنتج',
                                style: TextStyle(
                                    color: BranchColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11))),
                            Expanded(child: Text('المطلوب',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: BranchColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11))),
                            Expanded(flex: 2, child: Text('في المخزن',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: BranchColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11))),
                            Expanded(flex: 2, child: Text('المخصص',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: BranchColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11))),
                          ],
                        ),
                      ),
                      for (final r in _rows)
                        _ItemRow(row: r, enabled: !_busy, onChanged: () => setState(() {})),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Manual transfer section
                Text('التحكم اليدوي في النقل',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ManualButton(
                        label: 'نقل جزئي يدوي',
                        onTap: _busy ? null : _applyPartial,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ManualButton(
                        label: 'نقل كامل للمركز',
                        onTap: _busy ? null : _applyFull,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: BranchColors.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          // ── Footer ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: BranchColors.surfaceContainerLow,
              border: Border(
                top: BorderSide(color: BranchColors.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تاريخ التسليم المتوقع',
                    style: const TextStyle(
                        color: BranchColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(
                    _deliveryDate == null
                        ? 'اختر التاريخ'
                        : '${_deliveryDate!.year}-${_deliveryDate!.month.toString().padLeft(2, '0')}-${_deliveryDate!.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: _busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deliveryDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _deliveryDate = picked);
                        },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || !_canConfirm ? null : _confirm,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: BranchColors.onPrimary))
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                      _busy ? 'جارٍ التنفيذ…' : '✅ تأكيد التخصيص وإصدار الفاتورة'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                if (_hasInsufficientRows) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'بعض الأصناف تتجاوز الكمية المتوفرة — استخدم النقل الذكي أو عدّل الكميات.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BranchColors.warning, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowState {
  _RowState({
    required this.productId,
    required this.productName,
    required this.required,
    required this.available,
  }) : controller = TextEditingController(text: '$available');

  final String productId;
  final String productName;
  final int required;
  int available;
  final TextEditingController controller;
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.row, required this.enabled, required this.onChanged});

  final _RowState row;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final allocated = int.tryParse(row.controller.text.trim()) ?? 0;
    final sufficient = row.available >= row.required;
    final withinStock = allocated <= row.available;
    final chipColor = sufficient
        ? BranchColors.success
        : BranchColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BranchColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(row.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: BranchColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          Expanded(
            child: Text('${row.required}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: BranchColors.onSurface, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('${row.available} متاح',
                    style: TextStyle(
                        color: chipColor, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: withinStock ? BranchColors.outline : BranchColors.error,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: withinStock ? BranchColors.outline : BranchColors.error,
                    width: withinStock ? 1 : 2,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyButton extends StatelessWidget {
  const _StrategyButton({
    required this.label,
    required this.hint,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? BranchColors.onPrimary : BranchColors.primary;
    final bg = filled ? BranchColors.primary : BranchColors.surfaceContainerLowest;
    final border = filled
        ? null
        : Border.all(color: BranchColors.primary, width: 2);
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                Text(hint,
                    style: TextStyle(
                        color: filled ? fg.withValues(alpha: .85) : BranchColors.onSurfaceVariant,
                        fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualButton extends StatelessWidget {
  const _ManualButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        side: const BorderSide(color: BranchColors.outlineVariant),
        backgroundColor: BranchColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: BranchColors.secondary, fontWeight: FontWeight.w700)),
    );
  }
}