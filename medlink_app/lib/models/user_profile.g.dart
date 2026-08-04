// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      roleRaw: json['role'] as String,
      branchId: json['branch_id'] as String?,
      branchName: json['branch_name'] as String?,
      requiresPasswordChange:
          json['requires_password_change'] as bool? ?? false,
      accountStatusRaw: json['account_status'] as String? ?? 'pending_approval',
      termsAcceptedAt: json['terms_accepted_at'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.roleRaw,
      'branch_id': instance.branchId,
      'branch_name': instance.branchName,
      'requires_password_change': instance.requiresPasswordChange,
      'account_status': instance.accountStatusRaw,
      'terms_accepted_at': instance.termsAcceptedAt,
      'created_at': instance.createdAt,
    };
