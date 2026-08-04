import 'package:freezed_annotation/freezed_annotation.dart';
import 'product.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

/// Maps 1:1 to `public.order_items`, with optional joined product.
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'product_id') required String productId,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'is_bonus') @Default(false) bool isBonus,
    @JsonKey(name: 'created_at') String? createdAt,
    Product? product,
  }) = _OrderItem;

  const OrderItem._();

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
