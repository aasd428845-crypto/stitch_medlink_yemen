// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String,
      manufacturer: json['manufacturer'] as String?,
      dosageForm: json['dosage_form'] as String?,
      unit: json['unit'] as String? ?? 'علبة',
      unitPrice: (json['unit_price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'name_en': instance.nameEn,
      'description': instance.description,
      'category': instance.category,
      'manufacturer': instance.manufacturer,
      'dosage_form': instance.dosageForm,
      'unit': instance.unit,
      'unit_price': instance.unitPrice,
      'image_url': instance.imageUrl,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };
