// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promotional_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PromotionalOffer _$PromotionalOfferFromJson(Map<String, dynamic> json) {
  return _PromotionalOffer.fromJson(json);
}

/// @nodoc
mixin _$PromotionalOffer {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_text')
  String? get discountText => throw _privateConstructorUsedError;
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

  /// Serializes this PromotionalOffer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PromotionalOffer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PromotionalOfferCopyWith<PromotionalOffer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromotionalOfferCopyWith<$Res> {
  factory $PromotionalOfferCopyWith(
    PromotionalOffer value,
    $Res Function(PromotionalOffer) then,
  ) = _$PromotionalOfferCopyWithImpl<$Res, PromotionalOffer>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'discount_text') String? discountText,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'target_governorate') String? targetGovernorate,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$PromotionalOfferCopyWithImpl<$Res, $Val extends PromotionalOffer>
    implements $PromotionalOfferCopyWith<$Res> {
  _$PromotionalOfferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PromotionalOffer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? discountText = freezed,
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
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            discountText: freezed == discountText
                ? _value.discountText
                : discountText // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$PromotionalOfferImplCopyWith<$Res>
    implements $PromotionalOfferCopyWith<$Res> {
  factory _$$PromotionalOfferImplCopyWith(
    _$PromotionalOfferImpl value,
    $Res Function(_$PromotionalOfferImpl) then,
  ) = __$$PromotionalOfferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'discount_text') String? discountText,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'end_date') String? endDate,
    @JsonKey(name: 'target_governorate') String? targetGovernorate,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$PromotionalOfferImplCopyWithImpl<$Res>
    extends _$PromotionalOfferCopyWithImpl<$Res, _$PromotionalOfferImpl>
    implements _$$PromotionalOfferImplCopyWith<$Res> {
  __$$PromotionalOfferImplCopyWithImpl(
    _$PromotionalOfferImpl _value,
    $Res Function(_$PromotionalOfferImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PromotionalOffer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? discountText = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? targetGovernorate = freezed,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$PromotionalOfferImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        discountText: freezed == discountText
            ? _value.discountText
            : discountText // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$PromotionalOfferImpl extends _PromotionalOffer {
  const _$PromotionalOfferImpl({
    required this.id,
    required this.title,
    this.description,
    @JsonKey(name: 'image_url') this.imageUrl,
    @JsonKey(name: 'discount_text') this.discountText,
    @JsonKey(name: 'start_date') this.startDate,
    @JsonKey(name: 'end_date') this.endDate,
    @JsonKey(name: 'target_governorate') this.targetGovernorate,
    @JsonKey(name: 'is_active') this.isActive = true,
    @JsonKey(name: 'created_at') this.createdAt,
  }) : super._();

  factory _$PromotionalOfferImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromotionalOfferImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(name: 'discount_text')
  final String? discountText;
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
    return 'PromotionalOffer(id: $id, title: $title, description: $description, imageUrl: $imageUrl, discountText: $discountText, startDate: $startDate, endDate: $endDate, targetGovernorate: $targetGovernorate, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromotionalOfferImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.discountText, discountText) ||
                other.discountText == discountText) &&
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
    title,
    description,
    imageUrl,
    discountText,
    startDate,
    endDate,
    targetGovernorate,
    isActive,
    createdAt,
  );

  /// Create a copy of PromotionalOffer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PromotionalOfferImplCopyWith<_$PromotionalOfferImpl> get copyWith =>
      __$$PromotionalOfferImplCopyWithImpl<_$PromotionalOfferImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PromotionalOfferImplToJson(this);
  }
}

abstract class _PromotionalOffer extends PromotionalOffer {
  const factory _PromotionalOffer({
    required final String id,
    required final String title,
    final String? description,
    @JsonKey(name: 'image_url') final String? imageUrl,
    @JsonKey(name: 'discount_text') final String? discountText,
    @JsonKey(name: 'start_date') final String? startDate,
    @JsonKey(name: 'end_date') final String? endDate,
    @JsonKey(name: 'target_governorate') final String? targetGovernorate,
    @JsonKey(name: 'is_active') final bool isActive,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$PromotionalOfferImpl;
  const _PromotionalOffer._() : super._();

  factory _PromotionalOffer.fromJson(Map<String, dynamic> json) =
      _$PromotionalOfferImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(name: 'discount_text')
  String? get discountText;
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

  /// Create a copy of PromotionalOffer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PromotionalOfferImplCopyWith<_$PromotionalOfferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
