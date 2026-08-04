import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/inventory_item.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/inventory_quantity_tile.dart';

/// Branch inventory: current quantity per product with a quick edit dialog.
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
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: l10n.branchInventoryCurrentQuantity),
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
      onRefresh: branch.loadInventory,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (branch.inventoryError != null) ...[
            ErrorBanner(message: branch.inventoryError!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (branch.isLoadingInventory && branch.inventory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (branch.inventory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  l10n.branchNoInventory,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            for (final item in branch.inventory)
              InventoryQuantityTile(
                item: item,
                onEdit: () => _showEditDialog(context, item),
              ),
        ],
      ),
    );
  }
}
