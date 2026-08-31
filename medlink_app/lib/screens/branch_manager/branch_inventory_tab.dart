import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';

/// Full-catalog inventory screen: every active product with branch quantity,
/// nearest expiry, availability chips, editable quantities, batch modal,
/// search, glass filter cards and pagination.
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
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
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
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: BranchColors.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      PastelIconBadge(
                        icon: LucideIcons.packagePlus,
                        color: BranchColors.primary,
                        gradient: BranchColors.metricBlueGradient,
                        shape: BoxShape.circle,
                        size: 42,
                        iconSize: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'دفعة جديدة — ${row.name}',
                          style: Theme.of(sheetCtx)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GlassTextField(
                    controller: qtyCtrl,
                    label: 'الكمية المضافة',
                    icon: LucideIcons.hash,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Date picker button
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetCtx,
                        initialDate: expiry ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) setSheet(() => expiry = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.calendar,
                              size: 18,
                              color: BranchColors.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              expiry == null
                                  ? 'تاريخ انتهاء الصلاحية (اختياري)'
                                  : 'الانتهاء: ${expiry!.year}-${expiry!.month.toString().padLeft(2, '0')}-${expiry!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: expiry == null
                                    ? BranchColors.onSurfaceVariant
                                    : BranchColors.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (expiry != null)
                            GestureDetector(
                              onTap: () => setSheet(() => expiry = null),
                              child: const Icon(LucideIcons.x,
                                  size: 16,
                                  color: BranchColors.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _GradientSaveButton(
                    label: 'إضافة الدفعة',
                    gradient: BranchColors.metricBlueGradient,
                    onPressed: () async {
                      final qty = int.tryParse(qtyCtrl.text.trim());
                      if (qty == null || qty <= 0) return;
                      await context.read<BranchController>().addStockBatch(
                          productId: row.productId,
                          quantity: qty,
                          expiryDate: expiry);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    },
                  ),
                ],
              ),
            ),
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
            color: BranchColors.glassHeroGradient.first,
            backgroundColor: Colors.white,
            onRefresh: branch.loadCatalog,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // Hero header
                const BranchManagerHero(
                  title: 'المخزون',
                  subtitle:
                      'راقب مستويات المخزون وأضف دفعات جديدة بسهولة.',
                ),
                const SizedBox(height: 16),

                // Search field
                _GlassTextField(
                  controller: _searchCtrl,
                  label: 'ابحث عن منتج…',
                  icon: LucideIcons.search,
                  onChanged: (v) => setState(() {
                    _query = v;
                    _visible = _pageSize;
                  }),
                ),
                const SizedBox(height: 12),

                // Filter cards
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _InventoryFilterCard(
                        label: 'الكل',
                        icon: LucideIcons.layoutGrid,
                        gradient: BranchColors.glassHeroGradient,
                        selected: _filter == 'all',
                        onTap: () => setState(() {
                          _filter = 'all';
                          _visible = _pageSize;
                        }),
                      ),
                      _InventoryFilterCard(
                        label: 'متوفر',
                        icon: LucideIcons.checkCircle,
                        gradient: BranchColors.metricGreenGradient,
                        selected: _filter == 'available',
                        onTap: () => setState(() {
                          _filter = 'available';
                          _visible = _pageSize;
                        }),
                      ),
                      _InventoryFilterCard(
                        label: 'مخزون منخفض',
                        icon: LucideIcons.alertTriangle,
                        gradient: BranchColors.metricOrangeGradient,
                        selected: _filter == 'low',
                        onTap: () => setState(() {
                          _filter = 'low';
                          _visible = _pageSize;
                        }),
                      ),
                      _InventoryFilterCard(
                        label: 'تنتهي قريباً',
                        icon: LucideIcons.clock,
                        gradient: BranchColors.metricBlueGradient,
                        selected: _filter == 'expiring',
                        onTap: () => setState(() {
                          _filter = 'expiring';
                          _visible = _pageSize;
                        }),
                      ),
                      _InventoryFilterCard(
                        label: 'نفد',
                        icon: LucideIcons.xCircle,
                        gradient: [BranchColors.error, BranchColors.danger],
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

                // Errors
                if (branch.catalogError != null) ...[
                  ErrorBanner(message: branch.catalogError!),
                  const SizedBox(height: 12),
                ],

                // Content
                if (branch.isLoadingCatalog && branch.catalog.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 55),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  _EmptyInventory()
                else
                  for (final row in visible)
                    _CatalogCard(
                      row: row,
                      onEdit: () => _editQuantity(row),
                      onBatch: () => _addBatch(row),
                    ),

                // Load more
                if (filtered.length > _visible) ...[
                  const SizedBox(height: 10),
                  _GradientSaveButton(
                    label:
                        'عرض المزيد (${filtered.length - _visible} متبقي)',
                    gradient: BranchColors.glassPrimaryGradient,
                    onPressed: () =>
                        setState(() => _visible += _pageSize),
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

// ─── Inventory Filter Card ────────────────────────────────────────────────────

class _InventoryFilterCard extends StatelessWidget {
  const _InventoryFilterCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color:
                selected ? null : Colors.white.withValues(alpha: .80),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: .6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? gradient.first.withValues(alpha: .28)
                    : Colors.black.withValues(alpha: .04),
                blurRadius: selected ? 12 : 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : BranchColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : BranchColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Catalog Card ─────────────────────────────────────────────────────────────

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.row,
    required this.onEdit,
    required this.onBatch,
  });

  final CatalogRow row;
  final VoidCallback onEdit;
  final VoidCallback onBatch;

  (String label, List<Color> gradient) get _statusInfo {
    if (row.isOutOfStock) {
      return ('نفد', [BranchColors.error, BranchColors.danger]);
    }
    if (row.isLowStock) return ('منخفض', BranchColors.metricOrangeGradient);
    if (row.isExpiringSoon) return ('تنتهي قريباً', BranchColors.metricBlueGradient);
    return ('متوفر', BranchColors.metricGreenGradient);
  }

  @override
  Widget build(BuildContext context) {
    final (label, gradient) = _statusInfo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: .30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(LucideIcons.pill,
                  size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: BranchColors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.package,
                          size: 12,
                          color: BranchColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${row.quantity} ${row.unit}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: BranchColors.onSurfaceVariant),
                      ),
                      if (row.nearestExpiry != null) ...[
                        const SizedBox(width: 8),
                        Icon(LucideIcons.calendar,
                            size: 12,
                            color: BranchColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          row.nearestExpiry!.substring(0, 10),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: BranchColors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: .25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 4),

            // Actions
            IconButton(
              tooltip: 'تعديل الكمية',
              icon: const Icon(LucideIcons.pencil, size: 18),
              color: BranchColors.onSurfaceVariant,
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'دفعة جديدة',
              icon: const Icon(LucideIcons.plusCircle, size: 20),
              color: BranchColors.primary,
              onPressed: onBatch,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass Text Field ─────────────────────────────────────────────────────────

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
          color: BranchColors.onSurface, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
            color: BranchColors.onSurfaceVariant, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, size: 18, color: BranchColors.onSurfaceVariant),
        filled: true,
        fillColor: Colors.grey.shade100,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: BranchColors.glassHeroGradient.first, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Gradient Save Button ─────────────────────────────────────────────────────

class _GradientSaveButton extends StatelessWidget {
  const _GradientSaveButton({
    required this.label,
    required this.gradient,
    this.onPressed,
  });

  final String label;
  final List<Color> gradient;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: .35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyInventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: BranchColors.metricGreenGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                  color: BranchColors.metricGreenGradient.first
                      .withValues(alpha: .3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: const Icon(LucideIcons.packageSearch,
                color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          Text('لا توجد أصناف مطابقة',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 6),
          Text('جرّب تغيير الفلتر أو كلمة البحث.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}