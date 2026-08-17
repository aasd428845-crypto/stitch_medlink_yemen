import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/inventory_quantity_tile.dart';
import 'branch_manager_design.dart';

class BranchInventoryTab extends StatelessWidget {
  const BranchInventoryTab({super.key});

  Future<void> _showEditDialog(BuildContext context, InventoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: '${item.quantity}');
    final branch = context.read<BranchController>();
    final name = item.product?['name'] as String? ?? '';

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${l10n.branchInventoryEditQuantity} — $name'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.branchInventoryCurrentQuantity)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text.trim());
              if (qty == null || qty < 0) return;
              await branch.updateInventoryQuantity(item.id, qty);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(l10n.branchInventoryUpdate),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: const Color(0xFF102238),
      onRefresh: branch.loadInventory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Row(children: [
            Expanded(child: Text('المخزون', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: const Color(0xFF5AD9B6).withValues(alpha: .10), borderRadius: BorderRadius.circular(99)), child: Text('${branch.inventory.length} صنف', style: const TextStyle(color: Color(0xFF72E6C3), fontSize: 12, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 14),
          const BranchManagerSurface(
            child: Row(children: [
              Icon(Icons.inventory_2_rounded, color: Color(0xFF5AD9B6), size: 24),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مخزون الفرع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('راجع الكميات وحدّثها عند الاستلام أو التسوية.', style: TextStyle(color: Color(0xFF8EA3B1), fontSize: 12))])),
            ]),
          ),
          const SizedBox(height: 14),
          if (branch.inventoryError != null) ...[ErrorBanner(message: branch.inventoryError!), const SizedBox(height: 12)],
          if (branch.isLoadingInventory && branch.inventory.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 55), child: Center(child: CircularProgressIndicator()))
          else if (branch.inventory.isEmpty)
            BranchManagerSurface(child: Column(children: [const Icon(Icons.inventory_2_outlined, color: Color(0xFF6E8798), size: 38), const SizedBox(height: 10), Text(l10n.branchNoInventory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]))
          else
            for (final item in branch.inventory)
              Padding(padding: const EdgeInsets.only(bottom: 9), child: InventoryQuantityTile(item: item, onEdit: () => _showEditDialog(context, item))),
        ],
      ),
    );
  }
}
