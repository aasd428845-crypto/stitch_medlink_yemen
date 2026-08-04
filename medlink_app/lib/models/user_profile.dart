import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/constants.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Maps 1:1 to `public.users`. Field names and `@JsonKey` mappings must stay
/// character-for-character identical to the real snake_case columns defined
/// in supabase/migrations/0001_initial_schema.sql — do not rename or guess.
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    String? name,
    required String email,
    String? phone,
    @JsonKey(name: 'role') required String roleRaw,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'branch_name') String? branchName,
    @JsonKey(name: 'requires_password_change')
    @Default(false)
    bool requiresPasswordChange,
    @JsonKey(name: 'account_status')
    @Default('pending_approval')
    String accountStatusRaw,
    @JsonKey(name: 'terms_accepted_at') String? termsAcceptedAt,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _UserProfile;

  const UserProfile._();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  UserRole get role => UserRole.fromString(roleRaw);
  AccountStatus get accountStatus => AccountStatus.fromString(accountStatusRaw);
}
