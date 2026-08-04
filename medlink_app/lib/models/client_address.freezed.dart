// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_address.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ClientAddress _$ClientAddressFromJson(Map<String, dynamic> json) {
  return _ClientAddress.fromJson(json);
}

/// @nodoc
mixin _$ClientAddress {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String get clientId => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(name: 'address_text')
  String get addressText => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_default')
  bool get isDefault => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ClientAddress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientAddressCopyWith<ClientAddress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientAddressCopyWith<$Res> {
  factory $ClientAddressCopyWith(
    ClientAddress value,
    $Res Function(ClientAddress) then,
  ) = _$ClientAddressCopyWithImpl<$Res, ClientAddress>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'client_id') String clientId,
    String label,
    @JsonKey(name: 'address_text') String addressText,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'is_default') bool isDefault,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$ClientAddressCopyWithImpl<$Res, $Val extends ClientAddress>
    implements $ClientAddressCopyWith<$Res> {
  _$ClientAddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? label = null,
    Object? addressText = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? isDefault = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            clientId: null == clientId
                ? _value.clientId
                : clientId // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            addressText: null == addressText
                ? _value.addressText
                : addressText // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClientAddressImplCopyWith<$Res>
    implements $ClientAddressCopyWith<$Res> {
  factory _$$ClientAddressImplCopyWith(
    _$ClientAddressImpl value,
    $Res Function(_$ClientAddressImpl) then,
  ) = __$$ClientAddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'client_id') String clientId,
    String label,
    @JsonKey(name: 'address_text') String addressText,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'is_default') bool isDefault,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$ClientAddressImplCopyWithImpl<$Res>
    extends _$ClientAddressCopyWithImpl<$Res, _$ClientAddressImpl>
    implements _$$ClientAddressImplCopyWith<$Res> {
  __$$ClientAddressImplCopyWithImpl(
    _$ClientAddressImpl _value,
    $Res Function(_$ClientAddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClientAddress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? label = null,
    Object? addressText = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? isDefault = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ClientAddressImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        addressText: null == addressText
            ? _value.addressText
            : addressText // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientAddressImpl extends _ClientAddress {
  const _$ClientAddressImpl({
    required this.id,
    @JsonKey(name: 'client_id') required this.clientId,
    required this.label,
    @JsonKey(name: 'address_text') required this.addressText,
    this.latitude,
    this.longitude,
    @JsonKey(name: 'is_default') this.isDefault = false,
    @JsonKey(name: 'created_at') this.createdAt,
  }) : super._();

  factory _$ClientAddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientAddressImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'client_id')
  final String clientId;
  @override
  final String label;
  @override
  @JsonKey(name: 'address_text')
  final String addressText;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey(name: 'is_default')
  final bool isDefault;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'ClientAddress(id: $id, clientId: $clientId, label: $label, addressText: $addressText, latitude: $latitude, longitude: $longitude, isDefault: $isDefault, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientAddressImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.addressText, addressText) ||
                other.addressText == addressText) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clientId,
    label,
    addressText,
    latitude,
    longitude,
    isDefault,
    createdAt,
  );

  /// Create a copy of ClientAddress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientAddressImplCopyWith<_$ClientAddressImpl> get copyWith =>
      __$$ClientAddressImplCopyWithImpl<_$ClientAddressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientAddressImplToJson(this);
  }
}

abstract class _ClientAddress extends ClientAddress {
  const factory _ClientAddress({
    required final String id,
    @JsonKey(name: 'client_id') required final String clientId,
    required final String label,
    @JsonKey(name: 'address_text') required final String addressText,
    final double? latitude,
    final double? longitude,
    @JsonKey(name: 'is_default') final bool isDefault,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$ClientAddressImpl;
  const _ClientAddress._() : super._();

  factory _ClientAddress.fromJson(Map<String, dynamic> json) =
      _$ClientAddressImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'client_id')
  String get clientId;
  @override
  String get label;
  @override
  @JsonKey(name: 'address_text')
  String get addressText;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  @JsonKey(name: 'is_default')
  bool get isDefault;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of ClientAddress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientAddressImplCopyWith<_$ClientAddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
