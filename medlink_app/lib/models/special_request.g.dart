// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'special_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SpecialRequestImpl _$$SpecialRequestImplFromJson(Map<String, dynamic> json) =>
    _$SpecialRequestImpl(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$SpecialRequestImplToJson(
  _$SpecialRequestImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'client_id': instance.clientId,
  'product_name': instance.productName,
  'quantity': instance.quantity,
  'notes': instance.notes,
  'status': instance.status,
  'created_at': instance.createdAt,
};
