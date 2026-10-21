import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/cart_controller.dart';
import '../../services/order_service.dart';
import '../../utils/error_mapper.dart';
import '../../utils/theme.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/rate_driver_sheet.dart';
import '../../widgets/driver_location_map.dart';
import 'client_design.dart';
import '../../services/supabase_bootstrap.dart';
import 'order_cancel_section.dart';
import 'order_discount_section.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _existingRating;
  bool _ratingLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = context.read<OrderService>();
      _order = await service.fetchOrderDetails(widget.orderId);
      if (_order?.status == 'delivered') await _loadRating();
    } catch (e) {
      _error = mapAuthErrorToMessage(l10n, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }




  Future<void> _loadRating() async {
    try {
      final service = context.read<OrderService>();
      final rating = await service.fetchRatingForOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _existingRating = rating ?? {};
          _ratingLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ratingLoaded = true);
    }
  }

  Future<void> _reorder() async {
    final order = _order;
    if (order == null || order.items == null) return;
    final l10n = AppLocalizations.of(context)!;
    final payableItems = order.items!.where((item) => !item.isBonus).toList();
    if (payableItems.isEmpty) return;
    final service = context.read<OrderService>();
    final cart = context.read<CartController>();
    final products = await service.fetchCurrentProducts(
      payableItems.map((item) => item.productId).toSet().toList(),
    );
    if (!mounted) return;
    final byId = {for (final product in products) product.id: product};
    for (final item in payableItems) {
      final product = byId[item.productId];
      if (product != null) cart.addItem(product, item.quantity);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.reorderAddedToCart)));
  }

  void _openRatingSheet() {
    final order = _order;
    if (order == null) return;
    final driverId = order.assignedDriverId;
    if (driverId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Provider.value(
        value: context.read<OrderService>(),
        child: RateDriverSheet(
          orderId: order.id,
          driverId: driverId,
          onRated: (rating, comment) {
            setState(() {
              _existingRating = {'rating': rating, 'comment': comment};
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          backgroundColor: ClientColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: ClientColors.text,
          title: Text(
            _order != null
                ? '${l10n.orderNumber} ${_order!.id.substring(0, 8)}'
                : l10n.ordersTitle,
          ),
        ),
        body: ClientGlassBackground(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: ClientColors.danger,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
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
              : _OrderContent(
                  order: _order!,
                  l10n: l10n,
                  existingRating: _existingRating,
                  ratingLoaded: _ratingLoaded,
                  onRatePressed: _openRatingSheet,
                  onReorderPressed: _reorder,
                  onDiscountChanged: _load,
                ),
        ),
      ),
    );
  }
}

class _OrderContent extends StatelessWidget {
  const _OrderContent({
    required this.order,
    required this.l10n,
    required this.existingRating,
    required this.ratingLoaded,
    required this.onRatePressed,
    required this.onReorderPressed,
    required this.onDiscountChanged,
  });
  final OrderModel order;
  final AppLocalizations l10n;
  final Map<String, dynamic>? existingRating;
  final bool ratingLoaded;
  final VoidCallback onRatePressed;
  final VoidCallback onReorderPressed;
  final VoidCallback onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivered = order.status == 'delivered';
    final hasRating = existingRating != null && existingRating!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientCard(
            borderRadius: 24,
            tint: 0.82,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.orderNumber} ${order.id.substring(0, 8)}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (order.createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.createdAt!.substring(0, 10),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isDelivered && ratingLoaded) ...[
            if (hasRating)
              _RatingDisplay(
                rating: existingRating!['rating'] as int,
                comment: existingRating!['comment'] as String?,
                l10n: l10n,
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.star_outline_rounded),
                  label: Text(l10n.rateDriverTitle),
                  onPressed: onRatePressed,
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (order.deliveryAddress != null) ...[
            ClientSectionTitle(
              title: l10n.deliveryAddress,
              icon: Icons.location_on_outlined,
              iconColor: ClientColors.primary,
            ),
            const SizedBox(height: 10),
            ClientCard(
              borderRadius: 22,
              child: Row(
                children: [
                  ClientIconBadge(
                    icon: Icons.location_on_outlined,
                    color: ClientColors.primary,
                    size: 44,
                    iconSize: 20,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.deliveryAddress!.label,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.deliveryAddress!.addressText,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (order.scheduledDeliveryAt != null) ...[
            ClientCard(
              borderRadius: 22,
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ClientIconBadge(
                    icon: Icons.schedule_rounded,
                    color: ClientColors.primary,
                    size: 44,
                    iconSize: 20,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.driverScheduledDelivery,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.scheduledDeliveryAt!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (order.status == 'in_progress' &&
              order.assignedDriverId != null) ...[
            DriverLocationMap(driverId: order.assignedDriverId!),
            const SizedBox(height: 16),
          ],
          if (order.items != null && order.items!.isNotEmpty) ...[
            ClientSectionTitle(
              title: l10n.orderItemsSection,
              icon: Icons.inventory_2_outlined,
              iconColor: ClientColors.primarySoft,
            ),
            const SizedBox(height: 10),
            ClientCard(
              borderRadius: 24,
              tint: 0.78,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items!.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: ClientColors.outline.withValues(alpha: .5),
                ),
                itemBuilder: (context, i) {
                  final item = order.items![i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.product?.name ?? l10n.productFallback,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (item.isBonus)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ClientColors.primarySoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              l10n.autoBonusBadge,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: ClientColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('${l10n.quantityLabel}: ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.isBonus
                          ? '0 ﷼'
                          : '${(item.quantity * item.unitPrice).toStringAsFixed(0)} ﷼',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.isBonus
                            ? ClientColors.success
                            : ClientColors.primary,
                      ),
                        ),
                        const SizedBox(width: 8),
                        _RemoveItemButton(orderId: order.id, itemId: item.id, onAfterRemoval: () => onDiscountChanged()),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            ClientSectionTitle(
              title: l10n.orderNotes,
              icon: Icons.notes_rounded,
              iconColor: ClientColors.primary,
            ),
            const SizedBox(height: 10),
            ClientCard(
              borderRadius: 22,
              child: Text(order.notes!, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 16),
          ],
          ClientCard(
            borderRadius: 24,
            tint: 0.82,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.subtotal, style: theme.textTheme.bodyMedium),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} ﷼',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 18,
                          color: ClientColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.freeDelivery,
                          style: const TextStyle(
                            color: ClientColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      '0 ﷼',
                      style: TextStyle(
                        color: ClientColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 20,
                  color: ClientColors.outline.withValues(alpha: .5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.total, style: theme.textTheme.headlineSmall),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} ﷼',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: ClientColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (order.status == 'pending')
            OrderDiscountSection(
              orderId: order.id,
              status: order.status,
              totalAmount: order.totalAmount,
              onChanged: onDiscountChanged,
            ),
          OrderCancelSection(
            orderId: order.id,
            status: order.status,
            onChanged: onDiscountChanged,
          ),
          _AvailabilityResume(orderId: order.id, onChanged: () => onDiscountChanged()),
          _WaitingAction(orderId: order.id, status: order.status, onChanged: () => onDiscountChanged()),
          _AlternativePicker(orderId: order.id),
          if (isDelivered) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReorderPressed,
                icon: const Icon(Icons.replay_rounded),
                label: Text(l10n.reorderAddedToCart),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  const _RatingDisplay({
    required this.rating,
    required this.comment,
    required this.l10n,
  });
  final int rating;
  final String? comment;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClientCard(
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: ClientColors.primary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.yourRatingLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 22,
                color: ClientColors.primary,
              ),
            ),
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
class _RemoveItemButton extends StatefulWidget {
  const _RemoveItemButton({required this.orderId, required this.itemId, required this.onAfterRemoval});
  final String orderId;
  final String itemId;
  final VoidCallback onAfterRemoval;
  @override
  State<_RemoveItemButton> createState() => _RemoveItemButtonState();
}

class _RemoveItemButtonState extends State<_RemoveItemButton> {
  bool _busy = false;

  Future<void> _remove() async {
    final key = '${widget.orderId}_remove_${widget.itemId}_${DateTime.now().microsecondsSinceEpoch}';
    setState(() => _busy = true);
    try {
      await supabase.rpc('modify_order_item', params: {
        'p_order_id': widget.orderId,
        'p_order_item_id': widget.itemId,
        'p_operation': 'remove',
        'p_idempotency_key': key,
      });
      widget.onAfterRemoval();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إزالة المنتج من الطلب.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإزالة'),
        content: const Text('سيتم حذف المنتج من الطلب. قد يتغير إجمالي الطلب وقد يعاد احتساب خصم Bonus. أي refund مستحق سيعالجه النظام.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed == true) await _remove();
  }

  @override
  Widget build(BuildContext context) {
    return _busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : IconButton(onPressed: _confirm, icon: const Icon(Icons.delete_outline));
  }
}

class _AvailabilityResume extends StatefulWidget {
  const _AvailabilityResume({required this.orderId, required this.onChanged});
  final String orderId;
  final VoidCallback onChanged;
  @override
  State<_AvailabilityResume> createState() => _AvailabilityResumeState();
}

class _AvailabilityResumeState extends State<_AvailabilityResume> {
  bool _busy = false;
  bool _hasAvailable = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await supabase
          .from('order_shortage_events')
          .select()
          .eq('order_id', widget.orderId)
          .eq('event', 'available_again');
      setState(() => _hasAvailable = (res as List<dynamic>).isNotEmpty);
    } catch (_) {}
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await supabase.rpc('confirm_order_resume', params: {
        'p_order_id': widget.orderId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تأكيد متابعة الطلب')));
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAvailable) return const SizedBox.shrink();
    return Card(
      color: Colors.amber.shade50,
      child: ListTile(
        leading: const Icon(Icons.inventory_outlined, color: Colors.green),
        title: const Text('المنتج أصبح متوفرًا'),
        subtitle: const Text('الطلب لم يُستأنف تلقائيًا. يمكنك تأكيد متابعة الطلب.'),
        trailing: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(onPressed: _confirm, child: const Text('تأكيد المتابعة')),
      ),
    );
  }
}

class _WaitingAction extends StatefulWidget {
  const _WaitingAction({required this.orderId, required this.status, required this.onChanged});
  final String orderId;
  final String status;
  final VoidCallback onChanged;
  @override
  _WaitingActionState createState() => _WaitingActionState();
}

class _WaitingActionState extends State<_WaitingAction> {
  bool _busy = false;
  Future<void> _mark() async {
    setState(() => _busy = true);
    try {
      await supabase.rpc('set_order_waiting', params: {
        'p_order_id': widget.orderId,
        'p_reason': 'انتظار توفر المنتج',
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم وضع الطلب في حالة الانتظار')));
      widget.onChanged();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == 'waiting' || widget.status == 'delivered' || widget.status == 'cancelled') return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.hourglass_top_rounded),
        title: const Text('انتظار توفر المنتج'),
        subtitle: const Text('سيبقى الطلب في انتظار العميل دون auto-reactivation'),
        trailing: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(onPressed: _mark, child: const Text('انتظار')),
      ),
    );
  }
}

class _AlternativePicker extends StatefulWidget {
  const _AlternativePicker({required this.orderId});
  final String orderId;
  @override
  _AlternativePickerState createState() => _AlternativePickerState();
}

class _AlternativePickerState extends State<_AlternativePicker> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await supabase
          .from('order_alternatives')
          .select()
          .eq('order_id', widget.orderId)
          .order('created_at');
      if (!mounted) return;
      setState(() { _rows = (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList(); });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String id) async {
    setState(() => _busy.add(id));
    try {
      await supabase.rpc('select_order_alternative', params: {'p_alt_id': id});
      await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اختيار البديل')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final active = _rows.where((e) => e['status'] != 'REJECTED').toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('بدائل المنتجات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...active.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text('الحالة: ${row['status']}')),
                if (row['status'] == 'PROPOSED')
                  TextButton(
                    onPressed: _busy.contains(row['id']) ? null : () => _select(row['id']),
                    child: Text(_busy.contains(row['id']) ? 'جارٍ...' : 'اختيار هذا البديل'),
                  ),
              ]),
            )),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

