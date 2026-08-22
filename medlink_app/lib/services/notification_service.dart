import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';
import '../utils/constants.dart';

/// Single source of truth for notification operations.
///
/// Architecture rules (CLAUDE.md §3):
/// - Every Supabase call logs through SUPABASE_DEBUG.
/// - [isRead] is computed from the left-joined notification_reads array so we
///   avoid an extra round-trip; the field is injected before calling fromJson.
class NotificationService {
  NotificationService(this._client);

  final SupabaseClient _client;

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] NotificationService.$fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  void _logSuccess(String fn) {
    debugPrint('[${AppConstants.supabaseDebugTag}] NotificationService.$fn OK');
  }

  /// Fetches notifications relevant to the current user.
  ///
  /// RLS already filters by [target_role]; we additionally filter by
  /// [branchId] so branch-scoped notifications are isolated. The explicit
  /// client-side target check complements RLS and handles notifications that
  /// are addressed through target_user_ids.
  /// A left-join on [notification_reads] lets us compute [isRead] in one query.
  Future<List<NotificationModel>> fetchMyNotifications({
    String? branchId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      // PostgREST left-join: notification_reads rows filtered by RLS to the
      // calling user only (policy: user_id = auth.uid()).
      // Note: .or() must be called before .order() (filter vs. transform).
      var filterQuery = _client
          .from('notifications')
          .select('*, notification_reads!left(read_at)');

      final rows = await filterQuery.order('created_at', ascending: false);
      _logSuccess('fetchMyNotifications');

      return (rows as List).where((r) {
        final map = Map<String, dynamic>.from(r as Map);
        final role = map['target_role'] as String?;
        final targetUsers = (map['target_user_ids'] as List?)
                ?.map((id) => id.toString())
                .toSet() ??
            const <String>{};
        final roleMatches = role == null || role == 'client';
        final userMatches = targetUsers.isEmpty || targetUsers.contains(userId);
        final branchMatches = branchId == null ||
            map['target_branch_id'] == null ||
            map['target_branch_id'] == branchId;
        return roleMatches && userMatches && branchMatches;
      }).map((r) {
        final map = Map<String, dynamic>.from(r as Map);
        final reads = (map['notification_reads'] as List?) ?? [];
        // Remove the join array and inject computed bool before deserialising.
        map
          ..remove('notification_reads')
          ..['is_read'] = reads.isNotEmpty;
        return NotificationModel.fromJson(map);
      }).toList();
    } catch (e, st) {
      _logError('fetchMyNotifications', e, st);
      rethrow;
    }
  }

  /// Marks a single notification as read for the current user.
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('notification_reads').upsert(
        {
          'notification_id': notificationId,
          'user_id': userId,
        },
        onConflict: 'notification_id,user_id',
      );
      _logSuccess('markAsRead');
    } catch (e, st) {
      _logError('markAsRead', e, st);
      rethrow;
    }
  }

  /// Marks all given notification IDs as read in a single batch upsert.
  Future<void> markAllAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('notification_reads').upsert(
        notificationIds
            .map(
              (id) => {'notification_id': id, 'user_id': userId},
            )
            .toList(),
        onConflict: 'notification_id,user_id',
      );
      _logSuccess('markAllAsRead');
    } catch (e, st) {
      _logError('markAllAsRead', e, st);
      rethrow;
    }
  }
}
