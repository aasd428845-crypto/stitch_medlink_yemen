import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/faq_tile.dart';

/// Shared Help & Support screen — shown to all three roles (client,
/// branch manager, driver). Displays role-specific FAQs and contact links.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key, required this.role});

  final UserRole role;

  // ── Contact constants ────────────────────────────────────────────────────────
  static const _phoneNumber = '+967700000000';
  static const _whatsappNumber = '967700000000'; // no leading +
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
          _FaqEntry(
            q: 'كيف أطلب منتجاً؟',
            a: 'أضف المنتجات إلى السلة ثم اضغط "إتمام الطلب" واختر عنوان التوصيل.',
          ),
          _FaqEntry(
            q: 'كيف أتتبع طلبي؟',
            a: 'اذهب إلى تبويب "طلباتي" ثم اضغط على الطلب لرؤية حالته المحدّثة.',
          ),
          _FaqEntry(
            q: 'هل التوصيل مجاني؟',
            a: 'نعم، التوصيل مجاني على جميع الطلبات حالياً.',
          ),
          _FaqEntry(
            q: 'كيف أقيّم السائق؟',
            a: 'بعد استلام طلبك يظهر زر "قيّم السائق" في تفاصيل الطلب، اضغط عليه واختر عدد النجوم.',
          ),
          _FaqEntry(
            q: 'هل يمكنني إلغاء الطلب؟',
            a: 'يمكن إلغاء الطلب قبل تعيين السائق. للمساعدة تواصل معنا عبر واتساب.',
          ),
        ];
      case UserRole.branchManager:
        return [
          _FaqEntry(
            q: 'كيف أُعيّن سائقاً لطلب؟',
            a: 'افتح الطلب من تبويب "الطلبات" ثم اضغط زر "تعيين سائق" واختر السائق المناسب.',
          ),
          _FaqEntry(
            q: 'كيف أضيف سائقاً جديداً؟',
            a: 'اذهب إلى تبويب "السائقون" واضغط زر الإضافة، أدخل بيانات السائق وسيُرسل له كلمة مرور مؤقتة.',
          ),
          _FaqEntry(
            q: 'كيف أتحقق من مخزون الفرع؟',
            a: 'تبويب "المخزون" يعرض جميع المنتجات مع الكميات المتاحة، يمكنك تحديثها مباشرة.',
          ),
          _FaqEntry(
            q: 'كيف أرى متوسط تقييم السائق؟',
            a: 'في تبويب السائقين تجد بجانب كل سائق شارة تُظهر متوسط تقييمه وعدد التقييمات.',
          ),
          _FaqEntry(
            q: 'كيف أُعلَّق حساب سائق؟',
            a: 'اضغط على بطاقة السائق في تبويب السائقين ثم اختر "إيقاف".',
          ),
        ];
      case UserRole.driver:
        return [
          _FaqEntry(
            q: 'كيف أقبل طلباً وأبدأ التوصيل؟',
            a: 'يظهر الطلب في قائمة طلباتي بحالة "معيّن"، اضغط عليه ثم اضغط "بدء التوصيل" عند الانطلاق.',
          ),
          _FaqEntry(
            q: 'كيف أؤكد الاستلام؟',
            a: 'بعد تسليم الطلب للعميل اضغط "تأكيد التسليم" في شاشة تفاصيل الطلب.',
          ),
          _FaqEntry(
            q: 'كيف تُحسب عمولتي؟',
            a: 'تُحسب العمولة كنسبة مئوية من قيمة الطلب تُضاف تلقائياً بعد كل تسليم ناجح.',
          ),
          _FaqEntry(
            q: 'أين أرى تقييماتي؟',
            a: 'في تبويب "أرباحي" يظهر متوسط تقييمك وعدد التقييمات التي حصلت عليها.',
          ),
          _FaqEntry(
            q: 'ماذا أفعل إذا لم يكن العميل في المنزل؟',
            a: 'تواصل مع العميل عبر الاتصال، وإذا تعذّر التسليم تواصل مع مدير الفرع.',
          ),
        ];
      case UserRole.companyDirector:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final faqs = _getFaqs(l10n, role);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpSupportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── FAQ section ────────────────────────────────────────────────────
          Text(
            l10n.helpFaqSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in faqs)
            FaqTile(question: entry.q, answer: entry.a),

          const SizedBox(height: AppSpacing.lg),

          // ── Contact section ────────────────────────────────────────────────
          Text(
            l10n.helpContactSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _ContactTile(
            icon: Icons.phone_rounded,
            label: l10n.helpCallUs,
            subtitle: _phoneNumber,
            color: AppColors.primary,
            onTap: () => _launch('tel:$_phoneNumber'),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ContactTile(
            icon: Icons.chat_rounded,
            label: l10n.helpWhatsapp,
            subtitle: '+$_whatsappNumber',
            color: AppColors.success,
            onTap: () =>
                _launch('https://wa.me/$_whatsappNumber'),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ContactTile(
            icon: Icons.email_rounded,
            label: l10n.helpEmailUs,
            subtitle: _email,
            color: AppColors.secondary,
            onTap: () =>
                _launch('mailto:$_email?subject=MedLink Support'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Internal helpers ─────────────────────────────────────────────────────────

class _FaqEntry {
  const _FaqEntry({required this.q, required this.a});
  final String q;
  final String a;
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing:
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      ),
    );
  }
}
