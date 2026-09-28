import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/order_controller.dart';
import '../../utils/error_mapper.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

/// Server-driven customer order-cancellation section: cancel entry (pending
/// orders only) plus read-only cancellation history. All money, policy, and
/// identity decisions live in `cancel_order_with_discount` server-side; this
/// widget sends (orderId, reason) and displays stored rows verbatim.
/// No direct writes to orders, history, or ledger exist here.
class OrderCancelSection extends StatefulWidget {
  const OrderCancelSection({
    super.key,
    required this.orderId,
    required this.status,
    required this.onChanged,
  });

  final String orderId;
  final String status;
  final VoidCallback onChanged;

  @override
  State<OrderCancelSection> createState() => _OrderCancelSectionState();
}

class _OrderCancelSectionState extends State<OrderCancelSection> {
  @override
  void initState() {
    super.initState();
    // Post-frame: the load notifies listeners, illegal synchronously here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderController>().loadCancellationHistory(
            widget.orderId,
          );
    });
  }

  Future<void> _openCancelSheet() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _CancelSheet(
        orderId: widget.orderId,
        onDone: widget.onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final orderCtrl = context.watch<OrderController>();
    final history = orderCtrl.cancellationHistory
        .where((e) => e.orderId == widget.orderId)
        .toList();
    final canCancel = widget.status == 'pending';

    if (!canCancel && history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canCancel) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openCancelSheet,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(l10n.orderCancelAction),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (history.isNotEmpty) ...[
          ClientSectionTitle(
            title: l10n.orderCancelHistoryTitle,
            icon: Icons.history_rounded,
            iconColor: ClientColors.primary,
          ),
          const SizedBox(height: 10),
          ClientCard(
            borderRadius: 22,
            child: Column(
              children: [
                for (var i = 0; i < history.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 16,
                      color: ClientColors.outline.withValues(alpha: .5),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ClientIconBadge(
                        icon: Icons.cancel_rounded,
                        color: ClientColors.danger,
                        size: 40,
                        iconSize: 18,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              history[i].reason,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              history[i].cancelledAt.length >= 10
                                  ? history[i].cancelledAt.substring(0, 10)
                                  : history[i].cancelledAt,
                              style: theme.textTheme.bodySmall,
                            ),
                            if (history[i].reversalLedgerId != null)
                              Text(
                                l10n.orderDiscountApplied,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ClientColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Cancel bottom sheet with its own State lifecycle (owns the text
/// controller; watches the shared OrderController for busy/error).
/// Reason is free text (BD-2 undecided — no taxonomy); the RPC requires it.
class _CancelSheet extends StatefulWidget {
  const _CancelSheet({required this.orderId, required this.onDone});

  final String orderId;
  final VoidCallback onDone;

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _reasonEmpty = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final orderCtrl = context.read<OrderController>();
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonEmpty = true);
      return;
    }
    try {
      final id = await orderCtrl.cancelOrder(
        orderId: widget.orderId,
        reason: reason,
      );
      if (!mounted) return;
      if (id != null || orderCtrl.cancelError == null) {
        Navigator.pop(context, true);
        widget.onDone();
      }
    } catch (_) {
      // Error is exposed via orderCtrl.cancelError below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderCtrl = context.watch<OrderController>();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderCancelAction,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            enabled: !orderCtrl.isCancelling,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.orderCancelReasonHint,
              errorText:
                  _reasonEmpty ? l10n.orderCancelReasonEmpty : null,
              border: const OutlineInputBorder(),
            ),
          ),
          if (orderCtrl.cancelError != null) ...[
            const SizedBox(height: 8),
            Text(
              mapAuthErrorToMessage(l10n, orderCtrl.cancelError!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ClientColors.danger,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: orderCtrl.isCancelling ? null : _submit,
              icon: orderCtrl.isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(l10n.orderCancelConfirm),
            ),
          ),
        ],
      ),
    );
  }
}
