// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClientAddressImpl _$$ClientAddressImplFromJson(Map<String, dynamic> json) =>
    _$ClientAddressImpl(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      label: json['label'] as String,
      addressText: json['address_text'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$ClientAddressImplToJson(_$ClientAddressImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'label': instance.label,
      'address_text': instance.addressText,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'is_default': instance.isDefault,
      'created_at': instance.createdAt,
    };
