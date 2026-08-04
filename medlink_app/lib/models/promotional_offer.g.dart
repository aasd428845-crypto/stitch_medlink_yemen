// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotional_offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PromotionalOfferImpl _$$PromotionalOfferImplFromJson(
  Map<String, dynamic> json,
) => _$PromotionalOfferImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
  discountText: json['discount_text'] as String?,
  startDate: json['start_date'] as String?,
  endDate: json['end_date'] as String?,
  targetGovernorate: json['target_governorate'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$$PromotionalOfferImplToJson(
  _$PromotionalOfferImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'image_url': instance.imageUrl,
  'discount_text': instance.discountText,
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'target_governorate': instance.targetGovernorate,
  'is_active': instance.isActive,
  'created_at': instance.createdAt,
};
