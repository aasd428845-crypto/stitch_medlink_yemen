// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationModelImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  targetRole: json['target_role'] as String?,
  targetBranchId: json['target_branch_id'] as String?,
  relatedOfferId: json['related_offer_id'] as String?,
  createdBy: json['created_by'] as String?,
  createdAt: json['created_at'] as String?,
  isRead: json['is_read'] as bool? ?? false,
);

Map<String, dynamic> _$$NotificationModelImplToJson(
  _$NotificationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'target_role': instance.targetRole,
  'target_branch_id': instance.targetBranchId,
  'related_offer_id': instance.relatedOfferId,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt,
  'is_read': instance.isRead,
};
