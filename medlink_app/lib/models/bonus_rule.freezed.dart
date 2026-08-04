// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bonus_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BonusRule _$BonusRuleFromJson(Map<String, dynamic> json) {
  return _BonusRule.fromJson(json);
}

/// @nodoc
mixin _$BonusRule {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_id')
  String get productId => throw _privateConstructorUsedError;
  @JsonKey(name: 'buy_quantity')
  int get buyQuantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'free_quantity')
  int get freeQuantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_stackable')
  bool get isStackable => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_date')
  String? get startDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_date')
  String? get endDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_governorate')
  String? get targetGovernorate => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BonusRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BonusRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BonusRuleCopyWith<BonusRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BonusRuleCopyWith<$Res> {
  factory $BonusRuleCopyWith(BonusRule value, $Res Function(BonusRule) then) =
      _$BonusRuleCopyWithImpl<$Res, BonusRule>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'product_id') String productId,
    @JsonKey(name: 'buy_quantity') int buyQuantity,
    @JsonKey(name: 'free_quantity') int freeQuantity,
    @JsonKey(name: 'is_stackable') bool isStackable,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'target_governorate') String? targetGovernorate,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$BonusRuleCopyWithImpl<$Res, $Val extends BonusRule>
    implements $BonusRuleCopyWith<$Res> {
  _$BonusRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BonusRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? buyQuantity = null,
    Object? freeQuantity = null,
    Object? isStackable = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? targetGovernorate = freezed,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            buyQuantity: null == buyQuantity
                ? _value.buyQuantity
                : buyQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            freeQuantity: null == freeQuantity
                ? _value.freeQuantity
                : freeQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            isStackable: null == isStackable
                ? _value.isStackable
                : isStackable // ignore: cast_nullable_to_non_nullable
                      as bool,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetGovernorate: freezed == targetGovernorate
                ? _value.targetGovernorate
                : targetGovernorate // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
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
abstract class _$$BonusRuleImplCopyWith<$Res>
    implements $BonusRuleCopyWith<$Res> {
  factory _$$BonusRuleImplCopyWith(
    _$BonusRuleImpl value,
    $Res Function(_$BonusRuleImpl) then,
  ) = __$$BonusRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'product_id') String productId,
    @JsonKey(name: 'buy_quantity') int buyQuantity,
    @JsonKey(name: 'free_quantity') int freeQuantity,
    @JsonKey(name: 'is_stackable') bool isStackable,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'target_governorate') String? targetGovernorate,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$BonusRuleImplCopyWithImpl<$Res>
    extends _$BonusRuleCopyWithImpl<$Res, _$BonusRuleImpl>
    implements _$$BonusRuleImplCopyWith<$Res> {
  __$$BonusRuleImplCopyWithImpl(
    _$BonusRuleImpl _value,
    $Res Function(_$BonusRuleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BonusRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? buyQuantity = null,
    Object? freeQuantity = null,
    Object? isStackable = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? targetGovernorate = freezed,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$BonusRuleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        buyQuantity: null == buyQuantity
            ? _value.buyQuantity
            : buyQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        freeQuantity: null == freeQuantity
            ? _value.freeQuantity
            : freeQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        isStackable: null == isStackable
            ? _value.isStackable
            : isStackable // ignore: cast_nullable_to_non_nullable
                  as bool,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetGovernorate: freezed == targetGovernorate
            ? _value.targetGovernorate
            : targetGovernorate // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
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
class _$BonusRuleImpl extends _BonusRule {
  const _$BonusRuleImpl({
    required this.id,
    @JsonKey(name: 'product_id') required this.productId,
    @JsonKey(name: 'buy_quantity') required this.buyQuantity,
    @JsonKey(name: 'free_quantity') required this.freeQuantity,
    @JsonKey(name: 'is_stackable') this.isStackable = true,
    @JsonKey(name: 'start_date') this.startDate,
    @JsonKey(name: 'end_date') this.endDate,
    @JsonKey(name: 'target_governorate') this.targetGovernorate,
    @JsonKey(name: 'is_active') this.isActive = true,
    @JsonKey(name: 'created_at') this.createdAt,
  }) : super._();

  factory _$BonusRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$BonusRuleImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'product_id')
  final String productId;
  @override
  @JsonKey(name: 'buy_quantity')
  final int buyQuantity;
  @override
  @JsonKey(name: 'free_quantity')
  final int freeQuantity;
  @override
  @JsonKey(name: 'is_stackable')
  final bool isStackable;
  @override
  @JsonKey(name: 'start_date')
  final String? startDate;
  @override
  @JsonKey(name: 'end_date')
  final String? endDate;
  @override
  @JsonKey(name: 'target_governorate')
  final String? targetGovernorate;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'BonusRule(id: $id, productId: $productId, buyQuantity: $buyQuantity, freeQuantity: $freeQuantity, isStackable: $isStackable, startDate: $startDate, endDate: $endDate, targetGovernorate: $targetGovernorate, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BonusRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.buyQuantity, buyQuantity) ||
                other.buyQuantity == buyQuantity) &&
            (identical(other.freeQuantity, freeQuantity) ||
                other.freeQuantity == freeQuantity) &&
            (identical(other.isStackable, isStackable) ||
                other.isStackable == isStackable) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.targetGovernorate, targetGovernorate) ||
                other.targetGovernorate == targetGovernorate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    productId,
    buyQuantity,
    freeQuantity,
    isStackable,
    startDate,
    endDate,
    targetGovernorate,
    isActive,
    createdAt,
  );

  /// Create a copy of BonusRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BonusRuleImplCopyWith<_$BonusRuleImpl> get copyWith =>
      __$$BonusRuleImplCopyWithImpl<_$BonusRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BonusRuleImplToJson(this);
  }
}

abstract class _BonusRule extends BonusRule {
  const factory _BonusRule({
    required final String id,
    @JsonKey(name: 'product_id') required final String productId,
    @JsonKey(name: 'buy_quantity') required final int buyQuantity,
    @JsonKey(name: 'free_quantity') required final int freeQuantity,
    @JsonKey(name: 'is_stackable') final bool isStackable,
    @JsonKey(name: 'start_date') final String? startDate,
    @JsonKey(name: 'end_date') final String? endDate,
    @JsonKey(name: 'target_governorate') final String? targetGovernorate,
    @JsonKey(name: 'is_active') final bool isActive,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$BonusRuleImpl;
  const _BonusRule._() : super._();

  factory _BonusRule.fromJson(Map<String, dynamic> json) =
      _$BonusRuleImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'product_id')
  String get productId;
  @override
  @JsonKey(name: 'buy_quantity')
  int get buyQuantity;
  @override
  @JsonKey(name: 'free_quantity')
  int get freeQuantity;
  @override
  @JsonKey(name: 'is_stackable')
  bool get isStackable;
  @override
  @JsonKey(name: 'start_date')
  String? get startDate;
  @override
  @JsonKey(name: 'end_date')
  String? get endDate;
  @override
  @JsonKey(name: 'target_governorate')
  String? get targetGovernorate;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of BonusRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BonusRuleImplCopyWith<_$BonusRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
