// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'special_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SpecialRequest _$SpecialRequestFromJson(Map<String, dynamic> json) {
  return _SpecialRequest.fromJson(json);
}

/// @nodoc
mixin _$SpecialRequest {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String get clientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_name')
  String get productName => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this SpecialRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpecialRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpecialRequestCopyWith<SpecialRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpecialRequestCopyWith<$Res> {
  factory $SpecialRequestCopyWith(
    SpecialRequest value,
    $Res Function(SpecialRequest) then,
  ) = _$SpecialRequestCopyWithImpl<$Res, SpecialRequest>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'client_id') String clientId,
    @JsonKey(name: 'product_name') String productName,
    int quantity,
    String? notes,
    String status,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$SpecialRequestCopyWithImpl<$Res, $Val extends SpecialRequest>
    implements $SpecialRequestCopyWith<$Res> {
  _$SpecialRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpecialRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? productName = null,
    Object? quantity = null,
    Object? notes = freezed,
    Object? status = null,
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
            productName: null == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$SpecialRequestImplCopyWith<$Res>
    implements $SpecialRequestCopyWith<$Res> {
  factory _$$SpecialRequestImplCopyWith(
    _$SpecialRequestImpl value,
    $Res Function(_$SpecialRequestImpl) then,
  ) = __$$SpecialRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'client_id') String clientId,
    @JsonKey(name: 'product_name') String productName,
    int quantity,
    String? notes,
    String status,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$SpecialRequestImplCopyWithImpl<$Res>
    extends _$SpecialRequestCopyWithImpl<$Res, _$SpecialRequestImpl>
    implements _$$SpecialRequestImplCopyWith<$Res> {
  __$$SpecialRequestImplCopyWithImpl(
    _$SpecialRequestImpl _value,
    $Res Function(_$SpecialRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpecialRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? productName = null,
    Object? quantity = null,
    Object? notes = freezed,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$SpecialRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        productName: null == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$SpecialRequestImpl extends _SpecialRequest {
  const _$SpecialRequestImpl({
    required this.id,
    @JsonKey(name: 'client_id') required this.clientId,
    @JsonKey(name: 'product_name') required this.productName,
    this.quantity = 1,
    this.notes,
    this.status = 'pending',
    @JsonKey(name: 'created_at') this.createdAt,
  }) : super._();

  factory _$SpecialRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpecialRequestImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'client_id')
  final String clientId;
  @override
  @JsonKey(name: 'product_name')
  final String productName;
  @override
  @JsonKey()
  final int quantity;
  @override
  final String? notes;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'SpecialRequest(id: $id, clientId: $clientId, productName: $productName, quantity: $quantity, notes: $notes, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpecialRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clientId,
    productName,
    quantity,
    notes,
    status,
    createdAt,
  );

  /// Create a copy of SpecialRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpecialRequestImplCopyWith<_$SpecialRequestImpl> get copyWith =>
      __$$SpecialRequestImplCopyWithImpl<_$SpecialRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SpecialRequestImplToJson(this);
  }
}

abstract class _SpecialRequest extends SpecialRequest {
  const factory _SpecialRequest({
    required final String id,
    @JsonKey(name: 'client_id') required final String clientId,
    @JsonKey(name: 'product_name') required final String productName,
    final int quantity,
    final String? notes,
    final String status,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$SpecialRequestImpl;
  const _SpecialRequest._() : super._();

  factory _SpecialRequest.fromJson(Map<String, dynamic> json) =
      _$SpecialRequestImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'client_id')
  String get clientId;
  @override
  @JsonKey(name: 'product_name')
  String get productName;
  @override
  int get quantity;
  @override
  String? get notes;
  @override
  String get status;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of SpecialRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpecialRequestImplCopyWith<_$SpecialRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
