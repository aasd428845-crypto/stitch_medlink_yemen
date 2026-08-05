import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Maps 1:1 to `public.notifications` joined with `public.notification_reads`.
/// [isRead] is computed in [NotificationService] from the left-joined reads
/// array — it is NOT a real column; we inject it before calling [fromJson].
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String title,
    required String body,
    @JsonKey(name: 'target_role') String? targetRole,
    @JsonKey(name: 'target_branch_id') String? targetBranchId,
    @JsonKey(name: 'related_offer_id') String? relatedOfferId,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') String? createdAt,
    /// Injected by the service — true if the current user has a row in
    /// notification_reads for this notification.
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
