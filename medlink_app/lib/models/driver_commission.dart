/// Represents one row from public.driver_commissions, joined with the
/// related order's total_amount for display in the earnings tab.
class DriverCommission {
  const DriverCommission({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.orderTotalAmount,
    required this.createdAt,
  });

  final String id;
  final String orderId;

  /// The commission amount in local currency.
  final double amount;

  /// Either 'pending' or 'paid' — from driver_commissions.status.
  final String status;

  /// The full order total (from the joined orders.total_amount).
  final double orderTotalAmount;

  final DateTime createdAt;

  factory DriverCommission.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'] as Map<String, dynamic>?;
    return DriverCommission(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      orderTotalAmount: (orderJson?['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
