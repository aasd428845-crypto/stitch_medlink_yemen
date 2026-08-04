import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Maps 1:1 to `public.products`.
/// All @JsonKey names must match the snake_case column names in
/// supabase/migrations/0002_catalog_inventory_orders.sql exactly.
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    @JsonKey(name: 'name_en') String? nameEn,
    String? description,
    required String category,
    String? manufacturer,
    @JsonKey(name: 'dosage_form') String? dosageForm,
    @Default('علبة') String unit,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _Product;

  const Product._();

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
