import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/invoice.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';

/// Standalone invoice creation for the branch manager: pick a client,
/// set the amount and due date, then insert into `invoices` (policy
/// `invoices_branch_manager_insert`, migration 0009).
class BranchInvoiceCreateSheet extends StatefulWidget {
  const BranchInvoiceCreateSheet({super.key});

  @override
  State<BranchInvoiceCreateSheet> createState() =>
      _BranchInvoiceCreateSheetState();
}

class _BranchInvoiceCreateSheetState extends State<BranchInvoiceCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String? _clientId;
  DateTime? _dueDate;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branch = context.read<BranchController>();
      if (branch.clients.isEmpty && !branch.isLoadingClients) {
        branch.loadClients();
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _clientId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<BranchController>().createInvoice(
            clientId: _clientId!,
            amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
            dueDate: _dueDate,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الفاتورة بنجاح')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchController>();
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: BranchColors.heroGradient),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: BranchColors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('إنشاء فاتورة',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.md),
          ],
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _clientId,
                  decoration: const InputDecoration(
                    labelText: 'العميل',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    for (final c in branch.clients)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.name?.isNotEmpty == true
                              ? c.name!
                              : c.email,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _clientId = v),
                  validator: (v) =>
                      v == null ? 'اختر العميل' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'المبلغ (﷼)',
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
                    if (n == null || n <= 0) return 'أدخل مبلغاً صحيحاً';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(
                    _dueDate == null
                        ? 'تاريخ الاستحقاق (اختياري)'
                        : 'الاستحقاق: ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'إصدار الفاتورة',
                  onPressed: _submit,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status pill with a colored dot — مسدد / معلّق / متأخر / ملغي.
class InvoiceStatusChip extends StatelessWidget {
  const InvoiceStatusChip({super.key, required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (invoice.status) {
      'paid' => ('مسدد', BranchColors.success),
      'cancelled' => ('ملغي', BranchColors.onSurfaceVariant),
      _ when invoice.isOverdue => ('متأخر', BranchColors.error),
      _ => ('معلّق', BranchColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Tapping an invoice opens a compact detail view.
void showInvoiceDetail(BuildContext context, Invoice invoice) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('تفاصيل الفاتورة',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          BranchManagerSurface(
            child: Column(
              children: [
                _DetailRow(label: 'العميل', value: invoice.clientName ?? '—'),
                _DetailRow(
                    label: 'رقم الفاتورة',
                    value: invoice.id.substring(0, 8).toUpperCase()),
                _DetailRow(
                    label: 'المبلغ',
                    value: '${invoice.amount.toStringAsFixed(0)} ﷼'),
                _DetailRow(label: 'الحالة', value: '', chip: InvoiceStatusChip(invoice: invoice)),
                _DetailRow(
                    label: 'تاريخ الإنشاء',
                    value: invoice.createdAt?.substring(0, 10) ?? '—'),
                _DetailRow(
                    label: 'تاريخ الاستحقاق',
                    value: invoice.dueDate?.substring(0, 10) ?? '—'),
                if (invoice.paidAt != null)
                  _DetailRow(
                      label: 'تاريخ السداد',
                      value: invoice.paidAt!.substring(0, 10)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.chip});

  final String label;
  final String value;
  final Widget? chip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: BranchColors.onSurfaceVariant, fontSize: 13)),
          chip ?? Text(value,
              style: const TextStyle(
                  color: BranchColors.onSurface, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}