import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../branch_manager/branch_manager_design.dart';
import '../client/client_design.dart';

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
    final faqs = _getFaqs(l10n, role);
    final isClient = role == UserRole.client;

    return Theme(
      data: isClient ? AppTheme.clientLight : AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: isClient
            ? ClientColors.background
            : BranchColors.background,
        appBar: AppBar(
          backgroundColor: isClient
              ? ClientColors.surface
              : BranchColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: isClient
              ? ClientColors.text
              : BranchColors.onSurface,
          title: Text(l10n.helpSupportTitle),
        ),
        body: isClient
            ? ClientGlassBackground(
                child: _HelpContent(
                  faqs: faqs,
                  l10n: l10n,
                  isClient: isClient,
                  onLaunch: _launch,
                ),
              )
            : BranchGlassBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    BranchSectionTitle(
                      title: l10n.helpFaqSection,
                      icon: Icons.quiz_outlined,
                      iconColor: BranchColors.primary,
                    ),
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
                                PastelIconBadge(
                                  icon: Icons.question_mark_rounded,
                                  color: BranchColors.primary,
                                  size: 32,
                                  iconSize: 16,
                                  borderRadius: 10,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.q,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(right: 42),
                              child: Text(
                                entry.a,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    BranchSectionTitle(
                      title: l10n.helpContactSection,
                      icon: Icons.headset_mic_rounded,
                      iconColor: BranchColors.success,
                    ),
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
                      onTap: () =>
                          _launch('mailto:$_email?subject=MedLink Support'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HelpContent extends StatelessWidget {
  const _HelpContent({
    required this.faqs,
    required this.l10n,
    required this.isClient,
    required this.onLaunch,
  });

  final List<_FaqEntry> faqs;
  final AppLocalizations l10n;
  final bool isClient;
  final Future<void> Function(String url) onLaunch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ClientSectionTitle(
          title: l10n.helpFaqSection,
          icon: Icons.quiz_outlined,
          iconColor: ClientColors.primary,
        ),
        const SizedBox(height: 12),
        for (final entry in faqs) ...[
          ClientCard(
            margin: const EdgeInsets.only(bottom: 10),
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClientIconBadge(
                      icon: Icons.question_mark_rounded,
                      color: ClientColors.primary,
                      size: 32,
                      iconSize: 16,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.q,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 42),
                  child: Text(
                    entry.a,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        ClientSectionTitle(
          title: l10n.helpContactSection,
          icon: Icons.headset_mic_rounded,
          iconColor: ClientColors.success,
        ),
        const SizedBox(height: 12),
        _ContactTile(
          isClient: true,
          icon: Icons.phone_rounded,
          label: l10n.helpCallUs,
          subtitle: HelpSupportScreen._phoneNumber,
          color: ClientColors.primary,
          onTap: () => onLaunch('tel:${HelpSupportScreen._phoneNumber}'),
        ),
        _ContactTile(
          isClient: true,
          icon: Icons.chat_rounded,
          label: l10n.helpWhatsapp,
          subtitle: '+${HelpSupportScreen._whatsappNumber}',
          color: ClientColors.success,
          onTap: () =>
              onLaunch('https://wa.me/${HelpSupportScreen._whatsappNumber}'),
        ),
        _ContactTile(
          isClient: true,
          icon: Icons.email_rounded,
          label: l10n.helpEmailUs,
          subtitle: HelpSupportScreen._email,
          color: ClientColors.primaryDark,
          onTap: () => onLaunch(
            'mailto:${HelpSupportScreen._email}?subject=MedLink Support',
          ),
        ),
      ],
    );
  }
}

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
    this.isClient = false,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final card = isClient
        ? ClientCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            borderRadius: 22,
            child: _content(context),
          )
        : SoftCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            borderRadius: 22,
            child: _content(context),
          );
    return card;
  }

  Widget _content(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Row(
        children: [
          isClient
              ? ClientIconBadge(
                  icon: icon,
                  color: color,
                  size: 44,
                  iconSize: 20,
                  borderRadius: 14,
                )
              : PastelIconBadge(
                  icon: icon,
                  color: color,
                  size: 44,
                  iconSize: 20,
                  borderRadius: 14,
                ),
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
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isClient
                ? ClientColors.textMuted
                : BranchColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
