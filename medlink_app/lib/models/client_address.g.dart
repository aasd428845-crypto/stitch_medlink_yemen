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
      ownerName: json['owner_name'] as String?,
      phone: json['phone'] as String?,
      altPhone: json['alt_phone'] as String?,
      landmark: json['landmark'] as String?,
      governorate: json['governorate'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
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
      'owner_name': instance.ownerName,
      'phone': instance.phone,
      'alt_phone': instance.altPhone,
      'landmark': instance.landmark,
      'governorate': instance.governorate,
      'city': instance.city,
      'district': instance.district,
    };
