import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import 'branch_invoice_create_sheet.dart';
import 'branch_manager_design.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BranchInvoicesTab extends StatefulWidget {
  const BranchInvoicesTab({super.key});
  @override
  State<BranchInvoicesTab> createState() => _BranchInvoicesTabState();
}

class _BranchInvoicesTabState extends State<BranchInvoicesTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BranchController>().loadInvoices(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchController>();
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? branch.invoices
        : branch.invoices.where((i) {
            final client = (i.clientName ?? '').toLowerCase();
            final id = i.id.substring(0, 8).toLowerCase();
            return client.contains(query) || id.contains(query);
          }).toList();

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: branch.loadInvoices,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 68, 16, 120),
              children: [
                const BranchManagerHero(
                  title: 'الفواتير',
                  subtitle:
                      'سجل المبيعات الحقيقي للفرع — الفواتير، الدفعات، والمتأخرات في مكان واحد.',
                  gradient: ClientColors.heroGradient,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: BranchMetricTile(
                        label: 'إجمالي المبيعات',
                        value: '${branch.invoicesTotal.toStringAsFixed(0)} ﷼',
                        icon: LucideIcons.banknote,
                        color: ClientColors.primary,
                        gradient: const [ClientColors.primary],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BranchMetricTile(
                        label: 'مدفوعة',
                        value: '${branch.invoicesPaid.toStringAsFixed(0)} ﷼',
                        icon: LucideIcons.checkCircle,
                        color: ClientColors.success,
                        gradient: const [ClientColors.success],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BranchMetricTile(
                        label: 'متأخرة',
                        value: '${branch.overdueCount}',
                        icon: LucideIcons.clock,
                        color: ClientColors.danger,
                        gradient: const [ClientColors.danger],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const BranchInvoiceCreateSheet(),
                  ),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text(
                    'إنشاء فاتورة',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
                const SizedBox(height: 16),
                if (branch.invoicesError != null) ...[
                  ErrorBanner(message: branch.invoicesError!),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالعميل أو رقم الفاتورة…',
                    prefixIcon: const Icon(LucideIcons.search),
                    isDense: true,
                    filled: true,
                    fillColor: ClientColors.surface.withValues(alpha: .72),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: .7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (branch.isLoadingInvoices && branch.invoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 55),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  BranchManagerSurface(
                    margin: const EdgeInsets.only(top: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(26),
                      child: Column(
                        children: [
                          const Icon(
                            LucideIcons.receipt,
                            size: 40,
                            color: ClientColors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'لا توجد فواتير',
                            style: TextStyle(
                              color: ClientColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            query.isEmpty
                                ? 'أنشئ أول فاتورة للفرع أو انتظر طلبات التخصيص.'
                                : 'لا توجد نتائج مطابقة للبحث.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: ClientColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final invoice in filtered)
                    _InvoiceCard(
                      invoice: invoice,
                      onTap: () => showInvoiceDetail(context, invoice),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.onTap});

  final dynamic invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BranchManagerSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: ClientColors.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.receipt,
                color: ClientColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName?.isNotEmpty == true
                        ? invoice.clientName
                        : 'عميل',
                    style: const TextStyle(
                      color: ClientColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#${invoice.id.substring(0, 8).toUpperCase()} · ${invoice.createdAt?.substring(0, 10) ?? ''}',
                    style: const TextStyle(
                      color: ClientColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${invoice.amount.toStringAsFixed(0)} ﷼',
                  style: const TextStyle(
                    color: ClientColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                InvoiceStatusChip(invoice: invoice),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronLeft, color: ClientColors.textMuted),
          ],
        ),
      ),
    );
  }
}
