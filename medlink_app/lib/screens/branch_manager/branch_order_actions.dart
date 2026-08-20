import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import 'branch_allocate_sheet.dart';

/// Shared dialogs for order actions (allocate / assign driver / transfer /
/// reject), used by both the dashboard's recent-orders list and the full
/// orders tab so the logic lives in exactly one place.

/// Opens the smart allocation modal ("تفاصيل التخصيص").
void showAllocateSheet(BuildContext context, OrderModel order) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BranchAllocateSheet(order: order),
  );
}

Future<void> showAssignDriverDialog(BuildContext context, OrderModel order) async {
  final l10n = AppLocalizations.of(context)!;
  final branch = context.read<BranchController>();
  final drivers = branch.drivers;

  if (drivers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.branchNoDriversAvailable)),
    );
    return;
  }

  String? selectedDriverId;

  await showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) => AlertDialog(
        title: Text(l10n.branchAssignDriver),
        content: DropdownButtonFormField<String>(
          initialValue: selectedDriverId,
          decoration: InputDecoration(labelText: l10n.branchSelectDriver),
          items: [
            for (final d in drivers)
              DropdownMenuItem(
                value: d.id,
                child: Text(
                  branch.isDriverBusy(d.id)
                      ? '${d.name ?? d.email} (${l10n.branchDriverBusy})'
                      : d.name ?? d.email,
                ),
              ),
          ],
          onChanged: (v) => setState(() => selectedDriverId = v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: selectedDriverId == null
                ? null
                : () async {
                    await branch.assignDriver(order.id, selectedDriverId!);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
            child: Text(l10n.branchAssignDriver),
          ),
        ],
      ),
    ),
  );
}

Future<void> showTransferOrderDialog(BuildContext context, OrderModel order) async {
  final l10n = AppLocalizations.of(context)!;
  final branch = context.read<BranchController>();
  final branches = branch.otherBranches;

  if (branches.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.branchNoOtherBranches)),
    );
    return;
  }

  String? selectedBranchId;

  await showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) => AlertDialog(
        title: Text(l10n.branchTransferOrder),
        content: DropdownButtonFormField<String>(
          initialValue: selectedBranchId,
          decoration: InputDecoration(labelText: l10n.branchSelectBranch),
          items: [
            for (final b in branches)
              DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) => setState(() => selectedBranchId = v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: selectedBranchId == null
                ? null
                : () async {
                    await branch.transferOrder(order.id, selectedBranchId!);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
            child: Text(l10n.branchConfirmTransfer),
          ),
        ],
      ),
    ),
  );
}

Future<void> showRejectOrderConfirm(BuildContext context, OrderModel order) async {
  final l10n = AppLocalizations.of(context)!;
  final branch = context.read<BranchController>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(l10n.branchRejectOrder),
      content: Text(l10n.branchStatusUpdateConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: BranchColors.error),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(l10n.branchRejectOrder),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await branch.updateOrderStatus(order.id, 'cancelled');
  }
}