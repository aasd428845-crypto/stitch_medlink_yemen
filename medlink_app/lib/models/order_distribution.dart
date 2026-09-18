/// Physical distribution facts for one product in one order.
///
/// Paid sales and free bonus units are deliberately separate. The sum of the
/// two is the number of physical units that left inventory.
class OrderDistribution {
  const OrderDistribution({
    required this.orderId,
    required this.productId,
    required this.paidSalesQuantity,
    required this.bonusQuantity,
    required this.totalDistributedQuantity,
  });

  factory OrderDistribution.fromJson(Map<String, dynamic> json) {
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;

    return OrderDistribution(
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      paidSalesQuantity: number('paid_sales_quantity'),
      bonusQuantity: number('bonus_quantity'),
      totalDistributedQuantity: number('total_distributed_quantity'),
    );
  }

  final String orderId;
  final String productId;
  final int paidSalesQuantity;
  final int bonusQuantity;
  final int totalDistributedQuantity;
}