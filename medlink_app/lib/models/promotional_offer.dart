import 'package:freezed_annotation/freezed_annotation.dart';

part 'promotional_offer.freezed.dart';
part 'promotional_offer.g.dart';

/// Maps 1:1 to `public.promotional_offers`.
@freezed
class PromotionalOffer with _$PromotionalOffer {
  const factory PromotionalOffer({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'discount_text') String? discountText,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'target_governorate') String? targetGovernorate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _PromotionalOffer;

  const PromotionalOffer._();

  factory PromotionalOffer.fromJson(Map<String, dynamic> json) =>
      _$PromotionalOfferFromJson(json);
}
