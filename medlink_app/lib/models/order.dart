import 'package:freezed_annotation/freezed_annotation.dart';
import 'client_address.dart';
import 'order_item.dart';
import 'user_profile.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Maps 1:1 to `public.orders`.
@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String id,
    @JsonKey(name: 'client_id') required String clientId,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'parent_order_id') String? parentOrderId,
    @JsonKey(name: 'target_branches') List<String>? targetBranches,
    @Default('pending') String status,
    @JsonKey(name: 'delivery_address_id') String? deliveryAddressId,
    @JsonKey(name: 'assigned_driver_id') String? assignedDriverId,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'scheduled_delivery_at') String? scheduledDeliveryAt,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    // Joined relations
    @JsonKey(name: 'delivery_address') ClientAddress? deliveryAddress,
    List<OrderItem>? items,
    // Joined relations — only populated by BranchService queries
    // (branch manager screens); null for client-facing queries.
    UserProfile? client,
    @JsonKey(name: 'assigned_driver') UserProfile? assignedDriver,
  }) = _OrderModel;

  const OrderModel._();

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}
