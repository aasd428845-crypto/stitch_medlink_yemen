import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import 'auth_controller.dart';
import 'notification_service.dart';

/// State holder for the notification bell and the notifications screen.
///
/// Automatically reloads when the signed-in user changes (via [AuthController]
/// listener) so the unread badge stays current across role switches.
class NotificationController extends ChangeNotifier {
  NotificationController(this._service, this._authController) {
    _authController.addListener(_onAuthChanged);
    // Load immediately if a user is already signed in.
    if (_authController.profile != null) {
      loadNotifications();
    }
  }

  final NotificationService _service;
  final AuthController _authController;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  /// Number of unread notifications — used to drive the bell badge.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _onAuthChanged() {
    if (_authController.profile != null) {
      loadNotifications();
    } else {
      _notifications = [];
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final branchId = _authController.profile?.branchId;
      _notifications = await _service.fetchMyNotifications(branchId: branchId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a single notification as read — updates state locally immediately
  /// so the UI responds without waiting for a round-trip.
  Future<void> markAsRead(String notificationId) async {
    if (_notifications.any((n) => n.id == notificationId && n.isRead)) return;
    // Optimistic local update.
    _notifications = _notifications.map((n) {
      return n.id == notificationId ? n.copyWith(isRead: true) : n;
    }).toList();
    notifyListeners();
    try {
      await _service.markAsRead(notificationId);
    } catch (_) {
      // Revert on failure.
      _notifications = _notifications.map((n) {
        return n.id == notificationId ? n.copyWith(isRead: false) : n;
      }).toList();
      notifyListeners();
    }
  }

  /// Marks all unread notifications as read in one batch.
  Future<void> markAllAsRead() async {
    final unreadIds =
        _notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;
    // Optimistic local update.
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _service.markAllAsRead(unreadIds);
    } catch (_) {
      // Revert on failure.
      _notifications = _notifications.map((n) {
        return unreadIds.contains(n.id) ? n.copyWith(isRead: false) : n;
      }).toList();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}
