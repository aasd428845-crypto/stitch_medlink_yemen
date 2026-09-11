import 'dart:async';

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
    // Defer notification so callers that trigger this synchronously from
    // didChangeDependencies/build don't hit "setState called during build".
    scheduleMicrotask(notifyListeners);
    try {
      rooms = await loader();
    } catch (e) {
      // Show a user-friendly Arabic message instead of raw technical errors.
      final raw = e.toString().toLowerCase();
      if (raw.contains('relation') && raw.contains('does not exist')) {
        error = 'جداول الدردشة غير مفعّلة بعد في قاعدة البيانات. تواصل مع الدعم الفني.';
      } else if (raw.contains('permission denied') || raw.contains('rls')) {
        error = 'ليس لديك صلاحية الوصول للمحادثات. تحقق من إعدادات حسابك.';
      } else if (raw.contains('socket') || raw.contains('network') || raw.contains('timeout') || raw.contains('connection')) {
        error = 'تعذّر الاتصال بالخادم. تحقق من اتصال الإنترنت وأعد المحاولة.';
      } else {
        error = 'تعذّر تحميل المحادثات. تحقق من الاتصال وأعد المحاولة.';
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
