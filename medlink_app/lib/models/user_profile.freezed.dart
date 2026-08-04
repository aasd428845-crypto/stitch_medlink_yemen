// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'role')
  String get roleRaw => throw _privateConstructorUsedError;
  @JsonKey(name: 'branch_id')
  String? get branchId => throw _privateConstructorUsedError;
  @JsonKey(name: 'branch_name')
  String? get branchName => throw _privateConstructorUsedError;
  @JsonKey(name: 'requires_password_change')
  bool get requiresPasswordChange => throw _privateConstructorUsedError;
  @JsonKey(name: 'account_status')
  String get accountStatusRaw => throw _privateConstructorUsedError;
  @JsonKey(name: 'terms_accepted_at')
  String? get termsAcceptedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({
    String id,
    String? name,
    String email,
    String? phone,
    @JsonKey(name: 'role') String roleRaw,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'branch_name') String? branchName,
    @JsonKey(name: 'requires_password_change') bool requiresPasswordChange,
    @JsonKey(name: 'account_status') String accountStatusRaw,
    @JsonKey(name: 'terms_accepted_at') String? termsAcceptedAt,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? email = null,
    Object? phone = freezed,
    Object? roleRaw = null,
    Object? branchId = freezed,
    Object? branchName = freezed,
    Object? requiresPasswordChange = null,
    Object? accountStatusRaw = null,
    Object? termsAcceptedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            roleRaw: null == roleRaw
                ? _value.roleRaw
                : roleRaw // ignore: cast_nullable_to_non_nullable
                      as String,
            branchId: freezed == branchId
                ? _value.branchId
                : branchId // ignore: cast_nullable_to_non_nullable
                      as String?,
            branchName: freezed == branchName
                ? _value.branchName
                : branchName // ignore: cast_nullable_to_non_nullable
                      as String?,
            requiresPasswordChange: null == requiresPasswordChange
                ? _value.requiresPasswordChange
                : requiresPasswordChange // ignore: cast_nullable_to_non_nullable
                      as bool,
            accountStatusRaw: null == accountStatusRaw
                ? _value.accountStatusRaw
                : accountStatusRaw // ignore: cast_nullable_to_non_nullable
                      as String,
            termsAcceptedAt: freezed == termsAcceptedAt
                ? _value.termsAcceptedAt
                : termsAcceptedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? name,
    String email,
    String? phone,
    @JsonKey(name: 'role') String roleRaw,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'branch_name') String? branchName,
    @JsonKey(name: 'requires_password_change') bool requiresPasswordChange,
    @JsonKey(name: 'account_status') String accountStatusRaw,
    @JsonKey(name: 'terms_accepted_at') String? termsAcceptedAt,
    @JsonKey(name: 'created_at') String? createdAt,
  });
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? email = null,
    Object? phone = freezed,
    Object? roleRaw = null,
    Object? branchId = freezed,
    Object? branchName = freezed,
    Object? requiresPasswordChange = null,
    Object? accountStatusRaw = null,
    Object? termsAcceptedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$UserProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        roleRaw: null == roleRaw
            ? _value.roleRaw
            : roleRaw // ignore: cast_nullable_to_non_nullable
                  as String,
        branchId: freezed == branchId
            ? _value.branchId
            : branchId // ignore: cast_nullable_to_non_nullable
                  as String?,
        branchName: freezed == branchName
            ? _value.branchName
            : branchName // ignore: cast_nullable_to_non_nullable
                  as String?,
        requiresPasswordChange: null == requiresPasswordChange
            ? _value.requiresPasswordChange
            : requiresPasswordChange // ignore: cast_nullable_to_non_nullable
                  as bool,
        accountStatusRaw: null == accountStatusRaw
            ? _value.accountStatusRaw
            : accountStatusRaw // ignore: cast_nullable_to_non_nullable
                  as String,
        termsAcceptedAt: freezed == termsAcceptedAt
            ? _value.termsAcceptedAt
            : termsAcceptedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$UserProfileImpl extends _UserProfile {
  const _$UserProfileImpl({
    required this.id,
    this.name,
    required this.email,
    this.phone,
    @JsonKey(name: 'role') required this.roleRaw,
    @JsonKey(name: 'branch_id') this.branchId,
    @JsonKey(name: 'branch_name') this.branchName,
    @JsonKey(name: 'requires_password_change')
    this.requiresPasswordChange = false,
    @JsonKey(name: 'account_status') this.accountStatusRaw = 'pending_approval',
    @JsonKey(name: 'terms_accepted_at') this.termsAcceptedAt,
    @JsonKey(name: 'created_at') this.createdAt,
  }) : super._();

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String? name;
  @override
  final String email;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'role')
  final String roleRaw;
  @override
  @JsonKey(name: 'branch_id')
  final String? branchId;
  @override
  @JsonKey(name: 'branch_name')
  final String? branchName;
  @override
  @JsonKey(name: 'requires_password_change')
  final bool requiresPasswordChange;
  @override
  @JsonKey(name: 'account_status')
  final String accountStatusRaw;
  @override
  @JsonKey(name: 'terms_accepted_at')
  final String? termsAcceptedAt;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, phone: $phone, roleRaw: $roleRaw, branchId: $branchId, branchName: $branchName, requiresPasswordChange: $requiresPasswordChange, accountStatusRaw: $accountStatusRaw, termsAcceptedAt: $termsAcceptedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.roleRaw, roleRaw) || other.roleRaw == roleRaw) &&
            (identical(other.branchId, branchId) ||
                other.branchId == branchId) &&
            (identical(other.branchName, branchName) ||
                other.branchName == branchName) &&
            (identical(other.requiresPasswordChange, requiresPasswordChange) ||
                other.requiresPasswordChange == requiresPasswordChange) &&
            (identical(other.accountStatusRaw, accountStatusRaw) ||
                other.accountStatusRaw == accountStatusRaw) &&
            (identical(other.termsAcceptedAt, termsAcceptedAt) ||
                other.termsAcceptedAt == termsAcceptedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    email,
    phone,
    roleRaw,
    branchId,
    branchName,
    requiresPasswordChange,
    accountStatusRaw,
    termsAcceptedAt,
    createdAt,
  );

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(this);
  }
}

abstract class _UserProfile extends UserProfile {
  const factory _UserProfile({
    required final String id,
    final String? name,
    required final String email,
    final String? phone,
    @JsonKey(name: 'role') required final String roleRaw,
    @JsonKey(name: 'branch_id') final String? branchId,
    @JsonKey(name: 'branch_name') final String? branchName,
    @JsonKey(name: 'requires_password_change')
    final bool requiresPasswordChange,
    @JsonKey(name: 'account_status') final String accountStatusRaw,
    @JsonKey(name: 'terms_accepted_at') final String? termsAcceptedAt,
    @JsonKey(name: 'created_at') final String? createdAt,
  }) = _$UserProfileImpl;
  const _UserProfile._() : super._();

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  String get id;
  @override
  String? get name;
  @override
  String get email;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'role')
  String get roleRaw;
  @override
  @JsonKey(name: 'branch_id')
  String? get branchId;
  @override
  @JsonKey(name: 'branch_name')
  String? get branchName;
  @override
  @JsonKey(name: 'requires_password_change')
  bool get requiresPasswordChange;
  @override
  @JsonKey(name: 'account_status')
  String get accountStatusRaw;
  @override
  @JsonKey(name: 'terms_accepted_at')
  String? get termsAcceptedAt;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
