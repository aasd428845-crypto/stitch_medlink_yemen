import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';

/// Full-catalog inventory screen (Section 4): every active product with the
/// branch's quantity, nearest expiry date, availability chips, editable
/// quantities, "دفعة جديدة" batch modal (migration 0011 RPC), search,
/// status filters and pagination.
class BranchInventoryTab extends StatefulWidget {
  const BranchInventoryTab({super.key});
  @override
  State<BranchInventoryTab> createState() => _BranchInventoryTabState();
}

class _BranchInventoryTabState extends State<BranchInventoryTab> {
  static const _pageSize = 15;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'all'; // all | available | low | expiring | out
  int _visible = _pageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BranchController>().loadCatalog());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CatalogRow> _apply(List<CatalogRow> rows) {
    final q = _query.trim().toLowerCase();
    return rows.where((r) {
      if (q.isNotEmpty && !r.name.toLowerCase().contains(q)) return false;
      return switch (_filter) {
        'available' => !r.isOutOfStock && !r.isLowStock && !r.isExpiringSoon,
        'low' => r.isLowStock,
        'expiring' => r.isExpiringSoon,
        'out' => r.isOutOfStock,
        _ => true,
      };
    }).toList();
  }

  Future<void> _editQuantity(CatalogRow row) async {
    final controller = TextEditingController(text: '${row.quantity}');
    final branch = context.read<BranchController>();
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('تعديل الكمية — ${row.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الكمية'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text.trim());
              if (qty == null || qty < 0) return;
              await branch.setProductQuantity(row.productId, qty);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBatch(CatalogRow row) async {
    final qtyCtrl = TextEditingController();
    DateTime? expiry;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (sheetCtx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('دفعة جديدة — ${row.name}',
                        style: Theme.of(sheetCtx)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  expiry == null
                      ? 'تاريخ انتهاء الصلاحية (اختياري)'
                      : 'الانتهاء: ${expiry!.year}-${expiry!.month.toString().padLeft(2, '0')}-${expiry!.day.toString().padLeft(2, '0')}',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: sheetCtx,
                    initialDate: expiry ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setSheet(() => expiry = picked);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text.trim());
                  if (qty == null || qty <= 0) return;
                  await context
                      .read<BranchController>()
                      .addStockBatch(
                          productId: row.productId,
                          quantity: qty,
                          expiryDate: expiry);
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                },
                child: const Text('إضافة الدفعة',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchController>();
    final filtered = _apply(branch.catalog);
    final visible = filtered.take(_visible).toList();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: BranchColors.primary,
            backgroundColor: BranchColors.background,
            onRefresh: branch.loadCatalog,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('المخزون',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color: BranchColors.onSurface,
                                  fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: BranchColors.success.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${branch.catalog.length} صنف',
                          style: const TextStyle(
                              color: BranchColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() {
                    _query = v;
                    _visible = _pageSize;
                  }),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    filled: true,
                     fillColor: BranchColors.surfaceContainerLowest.withValues(alpha: .72),
                    border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(18),
                       borderSide: BorderSide(
                         color: BranchColors.onPrimary.withValues(alpha: .7),
                       ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        selected: _filter == 'all',
                        onTap: () => setState(() {
                          _filter = 'all';
                          _visible = _pageSize;
                        }),
                      ),
                      _FilterChip(
                        label: 'متوفر',
                        color: BranchColors.success,
                        selected: _filter == 'available',
                        onTap: () => setState(() {
                          _filter = 'available';
                          _visible = _pageSize;
                        }),
                      ),
                      _FilterChip(
                        label: 'مخزون منخفض',
                        color: BranchColors.warning,
                        selected: _filter == 'low',
                        onTap: () => setState(() {
                          _filter = 'low';
                          _visible = _pageSize;
                        }),
                      ),
                      _FilterChip(
                        label: 'تنتهي قريباً',
                        color: BranchColors.primary,
                        selected: _filter == 'expiring',
                        onTap: () => setState(() {
                          _filter = 'expiring';
                          _visible = _pageSize;
                        }),
                      ),
                      _FilterChip(
                        label: 'نفد',
                        color: BranchColors.error,
                        selected: _filter == 'out',
                        onTap: () => setState(() {
                          _filter = 'out';
                          _visible = _pageSize;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (branch.catalogError != null) ...[
                  ErrorBanner(message: branch.catalogError!),
                  const SizedBox(height: 12),
                ],
                if (branch.isLoadingCatalog && branch.catalog.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 55),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  BranchManagerSurface(
                    margin: const EdgeInsets.only(top: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(26),
                      child: Column(children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 40, color: BranchColors.onSurfaceVariant),
                        const SizedBox(height: 10),
                        const Text('لا توجد أصناف مطابقة',
                            style: TextStyle(
                                color: BranchColors.onSurface,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  )
                else
                  for (final row in visible)
                    _CatalogRowTile(
                      row: row,
                      onEdit: () => _editQuantity(row),
                      onBatch: () => _addBatch(row),
                    ),
                if (filtered.length > _visible) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _visible += _pageSize),
                      child: Text('عرض المزيد (${filtered.length - _visible} متبقي)'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = BranchColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? BranchColors.onPrimary : color,
                fontWeight: FontWeight.w700)),
        selected: selected,
        selectedColor: color,
        backgroundColor: BranchColors.surfaceContainerLowest,
        side: BorderSide(color: selected ? color : BranchColors.outlineVariant),
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _CatalogRowTile extends StatelessWidget {
  const _CatalogRowTile({
    required this.row,
    required this.onEdit,
    required this.onBatch,
  });

  final CatalogRow row;
  final VoidCallback onEdit;
  final VoidCallback onBatch;

  (String, Color) get _status {
    if (row.isOutOfStock) return ('نفد', BranchColors.error);
    if (row.isLowStock) return ('مخزون منخفض', BranchColors.warning);
    if (row.isExpiringSoon) return ('تنتهي قريباً', BranchColors.primary);
    return ('متوفر', BranchColors.success);
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _status;
    return BranchManagerSurface(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.medication_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: BranchColors.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(
                  [
                    '${row.quantity} ${row.unit}',
                    if (row.nearestExpiry != null)
                      '· ينتهي ${row.nearestExpiry!.substring(0, 10)}',
                  ].join(' '),
                  style: const TextStyle(
                      color: BranchColors.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: 'تعديل الكمية',
            icon: const Icon(Icons.edit_outlined, size: 19),
            color: BranchColors.onSurfaceVariant,
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'دفعة جديدة',
            icon: const Icon(Icons.add_box_rounded, size: 20),
            color: BranchColors.primary,
            onPressed: onBatch,
          ),
        ],
      ),
    );
  }
}