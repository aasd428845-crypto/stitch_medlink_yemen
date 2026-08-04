import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import '../utils/theme.dart';

/// One product row inside the branch inventory tab: name, quantity, a
/// green/yellow/red stock-level indicator, and an edit button.
class InventoryQuantityTile extends StatelessWidget {
  const InventoryQuantityTile({
    super.key,
    required this.item,
    required this.onEdit,
  });

  final InventoryItem item;
  final VoidCallback onEdit;

  Color _levelColor() {
    if (item.quantity <= 0) return AppColors.error;
    if (item.quantity < 10) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final product = item.product;
    final name = product?['name'] as String? ?? '—';
    final unit = product?['unit'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _levelColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.branchInventoryCurrentQuantity}: ${item.quantity} $unit',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
