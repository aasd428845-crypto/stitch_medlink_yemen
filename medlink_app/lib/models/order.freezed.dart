// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) {
  return _OrderModel.fromJson(json);
}

/// @nodoc
mixin _$OrderModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String get clientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'branch_id')
  String? get branchId => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_order_id')
  String? get parentOrderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_branches')
  List<String>? get targetBranches => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_address_id')
  String? get deliveryAddressId => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_driver_id')
  String? get assignedDriverId => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount')
  double get totalAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'scheduled_delivery_at')
  String? get scheduledDeliveryAt => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError; // Joined relations
  @JsonKey(name: 'delivery_address')
  ClientAddress? get deliveryAddress => throw _privateConstructorUsedError;
  List<OrderItem>? get items => throw _privateConstructorUsedError;

  /// Serializes this OrderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderModelCopyWith<OrderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderModelCopyWith<$Res> {
  factory $OrderModelCopyWith(
    OrderModel value,
    $Res Function(OrderModel) then,
  ) = _$OrderModelCopyWithImpl<$Res, OrderModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'client_id') String clientId,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'parent_order_id') String? parentOrderId,
    @JsonKey(name: 'target_branches') List<String>? targetBranches,
    String status,
    @JsonKey(name: 'delivery_address_id') String? deliveryAddressId,
    @JsonKey(name: 'assigned_driver_id') String? assignedDriverId,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'scheduled_delivery_at') String? scheduledDeliveryAt,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'delivery_address') ClientAddress? deliveryAddress,
    List<OrderItem>? items,
  });

  $ClientAddressCopyWith<$Res>? get deliveryAddress;
}

/// @nodoc
class _$OrderModelCopyWithImpl<$Res, $Val extends OrderModel>
    implements $OrderModelCopyWith<$Res> {
  _$OrderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? branchId = freezed,
    Object? parentOrderId = freezed,
    Object? targetBranches = freezed,
    Object? status = null,
    Object? deliveryAddressId = freezed,
    Object? assignedDriverId = freezed,
    Object? totalAmount = null,
    Object? scheduledDeliveryAt = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? deliveryAddress = freezed,
    Object? items = freezed,
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
            branchId: freezed == branchId
                ? _value.branchId
                : branchId // ignore: cast_nullable_to_non_nullable
                      as String?,
            parentOrderId: freezed == parentOrderId
                ? _value.parentOrderId
                : parentOrderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetBranches: freezed == targetBranches
                ? _value.targetBranches
                : targetBranches // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            deliveryAddressId: freezed == deliveryAddressId
                ? _value.deliveryAddressId
                : deliveryAddressId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedDriverId: freezed == assignedDriverId
                ? _value.assignedDriverId
                : assignedDriverId // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            scheduledDeliveryAt: freezed == scheduledDeliveryAt
                ? _value.scheduledDeliveryAt
                : scheduledDeliveryAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            deliveryAddress: freezed == deliveryAddress
                ? _value.deliveryAddress
                : deliveryAddress // ignore: cast_nullable_to_non_nullable
                      as ClientAddress?,
            items: freezed == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<OrderItem>?,
          )
          as $Val,
    );
  }

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientAddressCopyWith<$Res>? get deliveryAddress {
    if (_value.deliveryAddress == null) {
      return null;
    }

    return $ClientAddressCopyWith<$Res>(_value.deliveryAddress!, (value) {
      return _then(_value.copyWith(deliveryAddress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OrderModelImplCopyWith<$Res>
    implements $OrderModelCopyWith<$Res> {
  factory _$$OrderModelImplCopyWith(
    _$OrderModelImpl value,
    $Res Function(_$OrderModelImpl) then,
  ) = __$$OrderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'client_id') String clientId,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'parent_order_id') String? parentOrderId,
    @JsonKey(name: 'target_branches') List<String>? targetBranches,
    String status,
    @JsonKey(name: 'delivery_address_id') String? deliveryAddressId,
    @JsonKey(name: 'assigned_driver_id') String? assignedDriverId,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'scheduled_delivery_at') String? scheduledDeliveryAt,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'delivery_address') ClientAddress? deliveryAddress,
    List<OrderItem>? items,
  });

  @override
  $ClientAddressCopyWith<$Res>? get deliveryAddress;
}

/// @nodoc
class __$$OrderModelImplCopyWithImpl<$Res>
    extends _$OrderModelCopyWithImpl<$Res, _$OrderModelImpl>
    implements _$$OrderModelImplCopyWith<$Res> {
  __$$OrderModelImplCopyWithImpl(
    _$OrderModelImpl _value,
    $Res Function(_$OrderModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? branchId = freezed,
    Object? parentOrderId = freezed,
    Object? targetBranches = freezed,
    Object? status = null,
    Object? deliveryAddressId = freezed,
    Object? assignedDriverId = freezed,
    Object? totalAmount = null,
    Object? scheduledDeliveryAt = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
    Object? deliveryAddress = freezed,
    Object? items = freezed,
  }) {
    return _then(
      _$OrderModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        branchId: freezed == branchId
            ? _value.branchId
            : branchId // ignore: cast_nullable_to_non_nullable
                  as String?,
        parentOrderId: freezed == parentOrderId
            ? _value.parentOrderId
            : parentOrderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetBranches: freezed == targetBranches
            ? _value._targetBranches
            : targetBranches // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        deliveryAddressId: freezed == deliveryAddressId
            ? _value.deliveryAddressId
            : deliveryAddressId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedDriverId: freezed == assignedDriverId
            ? _value.assignedDriverId
            : assignedDriverId // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        scheduledDeliveryAt: freezed == scheduledDeliveryAt
            ? _value.scheduledDeliveryAt
            : scheduledDeliveryAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        deliveryAddress: freezed == deliveryAddress
            ? _value.deliveryAddress
            : deliveryAddress // ignore: cast_nullable_to_non_nullable
                  as ClientAddress?,
        items: freezed == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<OrderItem>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderModelImpl extends _OrderModel {
  const _$OrderModelImpl({
    required this.id,
    @JsonKey(name: 'client_id') required this.clientId,
    @JsonKey(name: 'branch_id') this.branchId,
    @JsonKey(name: 'parent_order_id') this.parentOrderId,
    @JsonKey(name: 'target_branches') final List<String>? targetBranches,
    this.status = 'pending',
    @JsonKey(name: 'delivery_address_id') this.deliveryAddressId,
    @JsonKey(name: 'assigned_driver_id') this.assignedDriverId,
    @JsonKey(name: 'total_amount') required this.totalAmount,
    @JsonKey(name: 'scheduled_delivery_at') this.scheduledDeliveryAt,
    this.notes,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'delivery_address') this.deliveryAddress,
    final List<OrderItem>? items,
  }) : _targetBranches = targetBranches,
       _items = items,
       super._();

  factory _$OrderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'client_id')
  final String clientId;
  @override
  @JsonKey(name: 'branch_id')
  final String? branchId;
  @override
  @JsonKey(name: 'parent_order_id')
  final String? parentOrderId;
  final List<String>? _targetBranches;
  @override
  @JsonKey(name: 'target_branches')
  List<String>? get targetBranches {
    final value = _targetBranches;
    if (value == null) return null;
    if (_targetBranches is EqualUnmodifiableListView) return _targetBranches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'delivery_address_id')
  final String? deliveryAddressId;
  @override
  @JsonKey(name: 'assigned_driver_id')
  final String? assignedDriverId;
  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @override
  @JsonKey(name: 'scheduled_delivery_at')
  final String? scheduledDeliveryAt;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  // Joined relations
  @override
  @JsonKey(name: 'delivery_address')
  final ClientAddress? deliveryAddress;
  final List<OrderItem>? _items;
  @override
  List<OrderItem>? get items {
    final value = _items;
    if (value == null) return null;
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, clientId: $clientId, branchId: $branchId, parentOrderId: $parentOrderId, targetBranches: $targetBranches, status: $status, deliveryAddressId: $deliveryAddressId, assignedDriverId: $assignedDriverId, totalAmount: $totalAmount, scheduledDeliveryAt: $scheduledDeliveryAt, notes: $notes, createdAt: $createdAt, deliveryAddress: $deliveryAddress, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.branchId, branchId) ||
                other.branchId == branchId) &&
            (identical(other.parentOrderId, parentOrderId) ||
                other.parentOrderId == parentOrderId) &&
            const DeepCollectionEquality().equals(
              other._targetBranches,
              _targetBranches,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.deliveryAddressId, deliveryAddressId) ||
                other.deliveryAddressId == deliveryAddressId) &&
            (identical(other.assignedDriverId, assignedDriverId) ||
                other.assignedDriverId == assignedDriverId) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.scheduledDeliveryAt, scheduledDeliveryAt) ||
                other.scheduledDeliveryAt == scheduledDeliveryAt) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.deliveryAddress, deliveryAddress) ||
                other.deliveryAddress == deliveryAddress) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clientId,
    branchId,
    parentOrderId,
    const DeepCollectionEquality().hash(_targetBranches),
    status,
    deliveryAddressId,
    assignedDriverId,
    totalAmount,
    scheduledDeliveryAt,
    notes,
    createdAt,
    deliveryAddress,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderModelImplCopyWith<_$OrderModelImpl> get copyWith =>
      __$$OrderModelImplCopyWithImpl<_$OrderModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderModelImplToJson(this);
  }
}

abstract class _OrderModel extends OrderModel {
  const factory _OrderModel({
    required final String id,
    @JsonKey(name: 'client_id') required final String clientId,
    @JsonKey(name: 'branch_id') final String? branchId,
    @JsonKey(name: 'parent_order_id') final String? parentOrderId,
    @JsonKey(name: 'target_branches') final List<String>? targetBranches,
    final String status,
    @JsonKey(name: 'delivery_address_id') final String? deliveryAddressId,
    @JsonKey(name: 'assigned_driver_id') final String? assignedDriverId,
    @JsonKey(name: 'total_amount') required final double totalAmount,
    @JsonKey(name: 'scheduled_delivery_at') final String? scheduledDeliveryAt,
    final String? notes,
    @JsonKey(name: 'created_at') final String? createdAt,
    @JsonKey(name: 'delivery_address') final ClientAddress? deliveryAddress,
    final List<OrderItem>? items,
  }) = _$OrderModelImpl;
  const _OrderModel._() : super._();

  factory _OrderModel.fromJson(Map<String, dynamic> json) =
      _$OrderModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'client_id')
  String get clientId;
  @override
  @JsonKey(name: 'branch_id')
  String? get branchId;
  @override
  @JsonKey(name: 'parent_order_id')
  String? get parentOrderId;
  @override
  @JsonKey(name: 'target_branches')
  List<String>? get targetBranches;
  @override
  String get status;
  @override
  @JsonKey(name: 'delivery_address_id')
  String? get deliveryAddressId;
  @override
  @JsonKey(name: 'assigned_driver_id')
  String? get assignedDriverId;
  @override
  @JsonKey(name: 'total_amount')
  double get totalAmount;
  @override
  @JsonKey(name: 'scheduled_delivery_at')
  String? get scheduledDeliveryAt;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt; // Joined relations
  @override
  @JsonKey(name: 'delivery_address')
  ClientAddress? get deliveryAddress;
  @override
  List<OrderItem>? get items;

  /// Create a copy of OrderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderModelImplCopyWith<_$OrderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
