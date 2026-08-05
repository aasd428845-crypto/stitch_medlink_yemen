import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../utils/constants.dart';

class ChatService {
  ChatService(this._client);

  final SupabaseClient _client;

  void _success(String method) =>
      debugPrint('[${AppConstants.supabaseDebugTag}] ChatService.$method OK');
  void _error(String method, Object error, StackTrace stackTrace) => debugPrint(
    '[${AppConstants.supabaseDebugTag}] ChatService.$method failed: $error\n$stackTrace',
  );

  Future<ChatRoom> getOrCreateRoom({
    required String orderId,
    required String driverId,
    required String branchId,
  }) async {
    try {
      final row = await _client
          .from('chat_rooms')
          .upsert({
            'order_id': orderId,
            'driver_id': driverId,
            'branch_id': branchId,
          }, onConflict: 'order_id')
          .select()
          .single();
      _success('getOrCreateRoom');
      return ChatRoom.fromJson(row);
    } catch (e, st) {
      _error('getOrCreateRoom', e, st);
      rethrow;
    }
  }

  Future<List<ChatRoom>> fetchRoomsForDriver() => _fetchRooms(
    _client
        .from('chat_rooms')
        .select('*, order:orders(id, status)')
        .eq('driver_id', _client.auth.currentUser!.id),
    'fetchRoomsForDriver',
  );

  Future<List<ChatRoom>> fetchRoomsForBranch(String branchId) => _fetchRooms(
    _client
        .from('chat_rooms')
        .select(
          '*, order:orders(id, status), driver:users!chat_rooms_driver_id_fkey(name, phone)',
        )
        .eq('branch_id', branchId),
    'fetchRoomsForBranch',
  );

  Future<List<ChatRoom>> _fetchRooms(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    String method,
  ) async {
    try {
      final rows = await query.order('created_at', ascending: false);
      _success(method);
      return rows.map(ChatRoom.fromJson).toList();
    } catch (e, st) {
      _error(method, e, st);
      rethrow;
    }
  }

  Future<List<ChatMessage>> fetchMessages(String roomId) async {
    try {
      final rows = await _client
          .from('chat_messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at');
      _success('fetchMessages');
      return (rows as List)
          .map((row) => ChatMessage.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _error('fetchMessages', e, st);
      rethrow;
    }
  }

  Future<void> sendMessage(String roomId, String content) async {
    try {
      await _client.from('chat_messages').insert({
        'room_id': roomId,
        'sender_id': _client.auth.currentUser!.id,
        'content': content,
      });
      _success('sendMessage');
    } catch (e, st) {
      _error('sendMessage', e, st);
      rethrow;
    }
  }

  RealtimeChannel subscribeToRoom(
    String roomId,
    void Function(ChatMessage) onNewMessage,
  ) => _client
      .channel('chat_room:$roomId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (payload) =>
            onNewMessage(ChatMessage.fromJson(payload.newRecord)),
      )
      .subscribe();

  Future<void> updateMyLocation(double latitude, double longitude) async {
    try {
      await _client.from('driver_locations').upsert({
        'driver_id': _client.auth.currentUser!.id,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _success('updateMyLocation');
    } catch (e, st) {
      _error('updateMyLocation', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchDriverLocation(String driverId) async {
    try {
      final row = await _client
          .from('driver_locations')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();
      _success('fetchDriverLocation');
      return row;
    } catch (e, st) {
      _error('fetchDriverLocation', e, st);
      rethrow;
    }
  }

  RealtimeChannel subscribeToDriverLocation(
    String driverId,
    void Function(Map<String, dynamic>) onUpdate,
  ) => _client
      .channel('driver_location:$driverId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'driver_locations',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'driver_id',
          value: driverId,
        ),
        callback: (payload) => onUpdate(payload.newRecord),
      )
      .subscribe();
}
