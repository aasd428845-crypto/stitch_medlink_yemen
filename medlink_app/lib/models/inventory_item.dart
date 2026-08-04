import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_item.freezed.dart';
part 'inventory_item.g.dart';

/// Maps to `public.inventory` joined with `public.products`.
/// When querying, use: inventory(*, product:products(*))
@freezed
class InventoryItem with _$InventoryItem {
  const factory InventoryItem({
    required String id,
    @JsonKey(name: 'branch_id') required String branchId,
    @JsonKey(name: 'product_id') required String productId,
    required int quantity,
    @JsonKey(name: 'updated_at') String? updatedAt,
    // Joined product data (nullable — may not always be fetched)
    Map<String, dynamic>? product,
  }) = _InventoryItem;

  const InventoryItem._();

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);
}
