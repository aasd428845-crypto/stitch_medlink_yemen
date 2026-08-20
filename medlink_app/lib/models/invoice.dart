/// Maps 1:1 to `public.invoices` (web migration 0004 + 0009/0010 Flutter).
/// Joined `client` is the client's `users` row (nullable — not always fetched).
class Invoice {
  const Invoice({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.createdAt,
    this.clientName,
  });

  final String id;
  final String clientId;
  final double amount;
  final String status;
  final String? dueDate;
  final String? paidAt;
  final String? createdAt;
  final String? clientName;

  bool get isOverdue =>
      status == 'pending' &&
      dueDate != null &&
      _dateOnly(dueDate!).isBefore(_today());

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    return Invoice(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      dueDate: json['due_date'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
      clientName: client?['name'] as String?,
    );
  }

  static DateTime _dateOnly(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? DateTime.now() : DateTime(d.year, d.month, d.day);
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}