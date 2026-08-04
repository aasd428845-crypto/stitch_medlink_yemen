import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/branch_controller.dart';
import '../../services/branch_service.dart';
import '../../utils/theme.dart';
import '../../widgets/order_status_chip.dart';
import 'branch_order_actions.dart';

/// Full order detail for the branch manager: client + address, item list
/// (including bonus lines), driver assignment, and a status-change action
/// gated behind a confirmation dialog.
class BranchOrderDetailScreen extends StatefulWidget {
  const BranchOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<BranchOrderDetailScreen> createState() => _BranchOrderDetailScreenState();
}

class _BranchOrderDetailScreenState extends State<BranchOrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;

  static const _nextStatus = {
    'pending': 'assigned',
    'assigned': 'in_progress',
    'in_progress': 'delivered',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _order = await context
          .read<BranchService>()
          .fetchOrderDetailForBranch(widget.orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.branchChangeStatus),
        content: Text(l10n.branchStatusUpdateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l10n.branchChangeStatus),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<BranchController>().updateOrderStatus(_order!.id, newStatus);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order != null
              ? '${l10n.orderNumber} ${_order!.id.substring(0, 8)}'
              : l10n.branchOrderDetailTitle,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? Center(child: Text(l10n.noOrdersFound))
                  : _buildContent(context, _order!, l10n),
    );
  }

  Widget _buildContent(BuildContext context, OrderModel order, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final nextStatus = _nextStatus[order.status];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.client?.name?.isNotEmpty == true
                            ? order.client!.name!
                            : l10n.orderNumber,
                        style: theme.textTheme.headlineSmall,
                      ),
                      OrderStatusChip(status: order.status),
                    ],
                  ),
                  if (order.client?.phone?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(order.client!.phone!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                  if (order.deliveryAddress != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(order.deliveryAddress!.addressText,
                              style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Driver assignment ────────────────────────────────────────
          Text(l10n.branchAssignDriver, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(
                order.assignedDriver?.name?.isNotEmpty == true
                    ? order.assignedDriver!.name!
                    : l10n.branchNoDriversAvailable,
              ),
              trailing: TextButton(
                onPressed: () async {
                  await showAssignDriverDialog(context, order);
                  await _load();
                },
                child: Text(l10n.branchSelectDriver),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Items ─────────────────────────────────────────────────────
          Text(l10n.orderItemsCount, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (final item in order.items ?? [])
                    ListTile(
                      dense: true,
                      leading: item.isBonus
                          ? const Icon(Icons.card_giftcard_rounded, color: AppColors.warning)
                          : const Icon(Icons.medication_outlined),
                      title: Text(item.product?.name ?? '—'),
                      subtitle: Text('${l10n.orderItemsCount}: ${item.quantity}'),
                      trailing: Text(
                        item.isBonus
                            ? l10n.autoBonusBadge
                            : '${(item.unitPrice * item.quantity).toStringAsFixed(0)} ﷼',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.isBonus ? AppColors.warning : null,
                        ),
                      ),
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.total, style: theme.textTheme.headlineSmall),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} ﷼',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (nextStatus != null)
            ElevatedButton.icon(
              onPressed: () => _changeStatus(nextStatus),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.branchChangeStatus),
            ),
        ],
      ),
    );
  }
}
