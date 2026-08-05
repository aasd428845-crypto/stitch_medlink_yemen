import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/driver_orders_controller.dart';
import '../../utils/theme.dart';

class DriverOrderDetailScreen extends StatefulWidget {
  const DriverOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<DriverOrderDetailScreen> createState() =>
      _DriverOrderDetailScreenState();
}

class _DriverOrderDetailScreenState extends State<DriverOrderDetailScreen> {
  bool _isUpdating = false;

  Future<void> _advance(OrderModel order, String newStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.read<DriverOrdersController>();
    final ok = await ctrl.advanceOrderStatus(order.id, newStatus);

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (ok) {
      final msg = newStatus == 'in_progress'
          ? l10n.driverDeliveryStarted
          : l10n.driverDeliveryConfirmed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.driverUpdateError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.watch<DriverOrdersController>();

    // Look up the order from the already-loaded list
    final order = ctrl.orders
        .cast<OrderModel?>()
        .firstWhere((o) => o?.id == widget.orderId, orElse: () => null);

    if (order == null) {
      // Edge case: arrived here before orders loaded
      return Scaffold(
        appBar: AppBar(title: Text(l10n.driverOrderDetailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final shortId = '#${order.id.substring(0, 8).toUpperCase()}';

    return Scaffold(
      appBar: AppBar(title: Text(shortId)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Client info ─────────────────────────────────────────────────
            _SectionCard(
              icon: Icons.person_rounded,
              title: order.client?.name ?? '—',
              children: [
                if (order.client?.phone != null)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: l10n.driverClientPhone,
                    value: order.client!.phone!,
                    trailing: IconButton(
                      icon: const Icon(Icons.call_outlined,
                          color: AppColors.primary),
                      onPressed: () async {
                        final uri = Uri(
                          scheme: 'tel',
                          path: order.client!.phone,
                        );
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Delivery address ─────────────────────────────────────────────
            _SectionCard(
              icon: Icons.location_on_rounded,
              title: l10n.driverDeliveryAddress,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    order.deliveryAddress?.addressText ?? '—',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (order.scheduledDeliveryAt != null &&
                    order.scheduledDeliveryAt!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: l10n.driverScheduledDelivery,
                    value: order.scheduledDeliveryAt!
                        .replaceFirst('T', ' ')
                        .substring(0, 16),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Items list ───────────────────────────────────────────────────
            _SectionCard(
              icon: Icons.inventory_2_outlined,
              title: l10n.driverOrderItems,
              children: [
                if (order.items == null || order.items!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      '—',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  for (final item in order.items!) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          if (item.isBonus)
                            Container(
                              margin:
                                  const EdgeInsets.only(left: AppSpacing.xs),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successContainer,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                'هدية',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.success),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.product?.name ?? item.productId,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '× ${item.quantity}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            item.isBonus
                                ? '0 ر.ي'
                                : '${(item.quantity * item.unitPrice).toStringAsFixed(0)} ر.ي',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: AppSpacing.md),
                  ],
                // Total row
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.total,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${order.totalAmount.toStringAsFixed(0)} ر.ي',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Notes ────────────────────────────────────────────────────────
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                icon: Icons.notes_rounded,
                title: l10n.orderNotes,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      order.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      // ── Action button ──────────────────────────────────────────────────────
      bottomNavigationBar: _buildActionBar(context, order, l10n),
    );
  }

  Widget? _buildActionBar(
    BuildContext context,
    OrderModel order,
    AppLocalizations l10n,
  ) {
    if (order.status == 'delivered') return null;

    final (label, icon, nextStatus) = order.status == 'assigned'
        ? (l10n.driverStartDelivery, Icons.local_shipping_rounded, 'in_progress')
        : (l10n.driverConfirmDelivery, Icons.check_circle_rounded, 'delivered');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: FilledButton.icon(
          onPressed: _isUpdating ? null : () => _advance(order, nextStatus),
          icon: _isUpdating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: order.status == 'in_progress'
                ? AppColors.success
                : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
