class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.branchId,
    required this.createdAt,
    this.orderStatus,
    this.driverName,
    this.lastMessage,
  });

  final String id;
  final String orderId;
  final String driverId;
  final String branchId;
  final DateTime createdAt;
  final String? orderStatus;
  final String? driverName;
  final String? lastMessage;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'];
    return ChatRoom(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      driverId: json['driver_id'] as String,
      branchId: json['branch_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      orderStatus: (json['order'] as Map?)?['status'] as String?,
      driverName: driver is Map ? driver['name'] as String? : null,
      lastMessage: json['last_message'] as String?,
    );
  }
}
