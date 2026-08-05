import 'package:flutter/material.dart';

import '../models/chat_room.dart';
import 'chat_service.dart';

class ChatController extends ChangeNotifier {
  ChatController(this._service);
  final ChatService _service;
  List<ChatRoom> rooms = [];
  bool isLoading = false;
  String? error;

  Future<void> loadDriverRooms() => _load(() => _service.fetchRoomsForDriver());
  Future<void> loadBranchRooms(String branchId) =>
      _load(() => _service.fetchRoomsForBranch(branchId));

  Future<ChatRoom> getOrCreateRoom({
    required String orderId,
    required String driverId,
    required String branchId,
  }) => _service.getOrCreateRoom(
    orderId: orderId,
    driverId: driverId,
    branchId: branchId,
  );

  Future<void> _load(Future<List<ChatRoom>> Function() loader) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      rooms = await loader();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
