import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/faq_tile.dart';
import '../branch_manager/branch_manager_design.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key, required this.role});

  final UserRole role;

  static const _phoneNumber = '+967700000000';
  static const _whatsappNumber = '967700000000';
  static const _email = 'support@medlink-ye.com';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<_FaqEntry> _getFaqs(AppLocalizations l10n, UserRole role) {
    switch (role) {
      case UserRole.client:
        return [
          _FaqEntry(q: 'كيف أطلب منتجاً؟', a: 'أضف المنتجات إلى السلة ثم اضغط "إتمام الطلب" واختر عنوان التوصيل.'),
          _FaqEntry(q: 'كيف أتتبع طلبي؟', a: 'اذهب إلى تبويب "طلباتي" ثم اضغط على الطلب لرؤية حالته المحدّثة.'),
          _FaqEntry(q: 'هل التوصيل مجاني؟', a: 'نعم، التوصيل مجاني على جميع الطلبات حالياً.'),
          _FaqEntry(q: 'كيف أقيّم السائق؟', a: 'بعد استلام طلبك يظهر زر "قيّم السائق" في تفاصيل الطلب، اضغط عليه واختر عدد النجوم.'),
          _FaqEntry(q: 'هل يمكنني إلغاء الطلب؟', a: 'يمكن إلغاء الطلب قبل تعيين السائق. للمساعدة تواصل معنا عبر واتساب.'),
        ];
      case UserRole.branchManager:
        return [
          _FaqEntry(q: 'كيف أُعيّن سائقاً لطلب؟', a: 'افتح الطلب من تبويب "الطلبات" ثم اضغط زر "تعيين سائق" واختر السائق المناسب.'),
          _FaqEntry(q: 'كيف أضيف سائقاً جديداً؟', a: 'اذهب إلى تبويب "السائقون" واضغط زر الإضافة، أدخل بيانات السائق وسيُرسل له كلمة مرور مؤقتة.'),
          _FaqEntry(q: 'كيف أتحقق من مخزون الفرع؟', a: 'تبويب "المخزون" يعرض جميع المنتجات مع الكميات المتاحة، يمكنك تحديثها مباشرة.'),
          _FaqEntry(q: 'كيف أرى متوسط تقييم السائق؟', a: 'في تبويب السائقين تجد بجانب كل سائق شارة تُظهر متوسط تقييمه وعدد التقييمات.'),
          _FaqEntry(q: 'كيف أُعلَّق حساب سائق؟', a: 'اضغط على بطاقة السائق في تبويب السائقين ثم اختر "إيقاف".'),
        ];
      case UserRole.driver:
        return [
          _FaqEntry(q: 'كيف أقبل طلباً وأبدأ التوصيل؟', a: 'يظهر الطلب في قائمة طلباتي بحالة "معيّن"، اضغط عليه ثم اضغط "بدء التوصيل" عند الانطلاق.'),
          _FaqEntry(q: 'كيف أؤكد الاستلام؟', a: 'بعد تسليم الطلب للعميل اضغط "تأكيد التسليم" في شاشة تفاصيل الطلب.'),
          _FaqEntry(q: 'كيف تُحسب عمولتي؟', a: 'تُحسب العمولة كنسبة مئوية من قيمة الطلب تُضاف تلقائياً بعد كل تسليم ناجح.'),
          _FaqEntry(q: 'أين أرى تقييماتي؟', a: 'في تبويب "أرباحي" يظهر متوسط تقييمك وعدد التقييمات التي حصلت عليها.'),
          _FaqEntry(q: 'ماذا أفعل إذا لم يكن العميل في المنزل؟', a: 'تواصل مع العميل عبر الاتصال، وإذا تعذّر التسليم تواصل مع مدير الفرع.'),
        ];
      case UserRole.companyDirector:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = _getFaqs(l10n, role);

    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: BranchColors.onSurface,
          title: Text(l10n.helpSupportTitle),
        ),
        body: BranchGlassBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              BranchSectionTitle(title: l10n.helpFaqSection, icon: Icons.quiz_outlined, iconColor: BranchColors.primary),
              const SizedBox(height: 12),
              for (final entry in faqs)
                SoftCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PastelIconBadge(icon: Icons.question_mark_rounded, color: BranchColors.primary, size: 32, iconSize: 16, borderRadius: 10),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.q, style: Theme.of(context).textTheme.titleSmall)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 42),
                        child: Text(entry.a, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              BranchSectionTitle(title: l10n.helpContactSection, icon: Icons.headset_mic_rounded, iconColor: BranchColors.success),
              const SizedBox(height: 12),
              _ContactTile(
                icon: Icons.phone_rounded,
                label: l10n.helpCallUs,
                subtitle: _phoneNumber,
                color: BranchColors.primary,
                onTap: () => _launch('tel:$_phoneNumber'),
              ),
              _ContactTile(
                icon: Icons.chat_rounded,
                label: l10n.helpWhatsapp,
                subtitle: '+$_whatsappNumber',
                color: BranchColors.success,
                onTap: () => _launch('https://wa.me/$_whatsappNumber'),
              ),
              _ContactTile(
                icon: Icons.email_rounded,
                label: l10n.helpEmailUs,
                subtitle: _email,
                color: BranchColors.primaryContainer,
                onTap: () => _launch('mailto:$_email?subject=MedLink Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqEntry {
  const _FaqEntry({required this.q, required this.a});
  final String q;
  final String a;
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Row(
          children: [
            PastelIconBadge(icon: icon, color: color, size: 44, iconSize: 20, borderRadius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: BranchColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}