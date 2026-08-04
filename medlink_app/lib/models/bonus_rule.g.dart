// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonus_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BonusRuleImpl _$$BonusRuleImplFromJson(Map<String, dynamic> json) =>
    _$BonusRuleImpl(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      buyQuantity: (json['buy_quantity'] as num).toInt(),
      freeQuantity: (json['free_quantity'] as num).toInt(),
      isStackable: json['is_stackable'] as bool? ?? true,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      targetGovernorate: json['target_governorate'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$BonusRuleImplToJson(_$BonusRuleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'buy_quantity': instance.buyQuantity,
      'free_quantity': instance.freeQuantity,
      'is_stackable': instance.isStackable,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'target_governorate': instance.targetGovernorate,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };
