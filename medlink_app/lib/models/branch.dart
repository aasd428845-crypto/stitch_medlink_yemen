import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch.freezed.dart';
part 'branch.g.dart';

/// Maps 1:1 to `public.branches` from 0001_initial_schema.sql.
@freezed
class Branch with _$Branch {
  const factory Branch({
    required String id,
    required String name,
    String? governorate,
    @JsonKey(name: 'address_text') String? addressText,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _Branch;

  factory Branch.fromJson(Map<String, dynamic> json) => _$BranchFromJson(json);
}
