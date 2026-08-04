import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsAndConditions)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'شروط استخدام منصة ميدلينك اليمن\n\n'
          'هذا التطبيق مخصص حصراً للمنشآت الطبية المرخصة (مستشفيات، صيدليات) '
          'المتعاقدة مع الشركة. يخضع كل حساب جديد لمراجعة إدارية إلزامية قبل '
          'التفعيل. جميع عمليات التوصيل مجانية بالكامل ولا تُفرض أي رسوم إضافية. '
          'باستخدامك للتطبيق فإنك توافق على سياسة الخصوصية الخاصة بمعالجة '
          'بياناتك وطلباتك وفق الأنظمة المعمول بها في الجمهورية اليمنية.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
