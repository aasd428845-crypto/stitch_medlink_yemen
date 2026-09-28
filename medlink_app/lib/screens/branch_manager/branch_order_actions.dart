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

Future<void> showAssignDriverDialog(
  BuildContext context,
  OrderModel order,
) async {
  final l10n = AppLocalizations.of(context)!;
  final branch = context.read<BranchController>();
  final drivers = branch.drivers;

  if (drivers.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.branchNoDriversAvailable)));
    return;
  }

  String? selectedDriverId;

  await showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) => AlertDialog(
        title: Text(l10n.branchAssignDriver),
        content: DropdownButtonFormField<String>(
          value: selectedDriverId,
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

Future<void> showTransferOrderDialog(
  BuildContext context,
  OrderModel order,
) async {
  final l10n = AppLocalizations.of(context)!;
  final branch = context.read<BranchController>();
  final branches = branch.otherBranches;

  if (branches.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.branchNoOtherBranches)));
    return;
  }

  String? selectedBranchId;

  await showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) => AlertDialog(
        title: Text(l10n.branchTransferOrder),
        content: DropdownButtonFormField<String>(
          value: selectedBranchId,
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

Future<void> showRejectOrderConfirm(
  BuildContext context,
  OrderModel order,
) async {
  await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => _RejectOrderDialog(order: order),
  );
}

/// Cancel dialog owned lifecycle: text controller is created and disposed
/// with the dialog State, so no rebuild can touch it after disposal.
/// Submits through [BranchController.cancelOrderWithDiscount] (financial
/// RPC) — never a direct status write.
class _RejectOrderDialog extends StatefulWidget {
  const _RejectOrderDialog({required this.order});

  final OrderModel order;

  @override
  State<_RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<_RejectOrderDialog> {
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _reasonEmpty = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonEmpty = true);
      return;
    }
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
      _reasonEmpty = false;
    });
    try {
      await context.read<BranchController>().cancelOrderWithDiscount(
            orderId: widget.order.id,
            reason: reason,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.branchRejectOrder),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.branchStatusUpdateConfirm),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              enabled: !_submitting,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.branchCancelReasonHint,
                errorText:
                    _reasonEmpty ? l10n.branchCancelReasonEmpty : null,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BranchColors.error,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: BranchColors.error),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.branchRejectOrder),
        ),
      ],
    );
  }
}
