// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderModelImpl _$$OrderModelImplFromJson(Map<String, dynamic> json) =>
    _$OrderModelImpl(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      branchId: json['branch_id'] as String?,
      parentOrderId: json['parent_order_id'] as String?,
      targetBranches: (json['target_branches'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: json['status'] as String? ?? 'pending',
      deliveryAddressId: json['delivery_address_id'] as String?,
      assignedDriverId: json['assigned_driver_id'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      scheduledDeliveryAt: json['scheduled_delivery_at'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      deliveryAddress: json['delivery_address'] == null
          ? null
          : ClientAddress.fromJson(
              json['delivery_address'] as Map<String, dynamic>,
            ),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$OrderModelImplToJson(_$OrderModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'branch_id': instance.branchId,
      'parent_order_id': instance.parentOrderId,
      'target_branches': instance.targetBranches,
      'status': instance.status,
      'delivery_address_id': instance.deliveryAddressId,
      'assigned_driver_id': instance.assignedDriverId,
      'total_amount': instance.totalAmount,
      'scheduled_delivery_at': instance.scheduledDeliveryAt,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'delivery_address': instance.deliveryAddress?.toJson(),
      'items': instance.items?.map((e) => e.toJson()).toList(),
    };
