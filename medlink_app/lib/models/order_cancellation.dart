import 'package:flutter/foundation.dart';

/// One row of `public.order_cancellations`, written server-side inside the
/// cancel transaction only. Read-only from the client: no insert, update,
/// or delete path exists in the app, and RLS exposes no write policies.
/// Display only: values are shown verbatim, never recomputed.
@immutable
class OrderCancellation {
  const OrderCancellation({
    required this.id,
    required this.orderId,
    required this.reason,
    this.reasonCode,
    this.note,
    this.cancelledBy,
    required this.cancelledAt,
    required this.previousStatus,
    required this.source,
    this.reversalLedgerId,
    this.idempotencyKey,
    required this.createdAt,
  });

  factory OrderCancellation.fromJson(Map<String, dynamic> json) {
    return OrderCancellation(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      reasonCode: json['reason_code'] as String?,
      note: json['note'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledAt: json['cancelled_at'] as String? ?? '',
      previousStatus: json['previous_status'] as String? ?? '',
      source: json['source'] as String? ?? '',
      reversalLedgerId: json['reversal_ledger_id'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String id;
  final String orderId;
  final String reason;
  final String? reasonCode;
  final String? note;
  final String? cancelledBy;
  final String cancelledAt;
  final String previousStatus;
  final String source;
  final String? reversalLedgerId;
  final String? idempotencyKey;
  final String createdAt;
}
