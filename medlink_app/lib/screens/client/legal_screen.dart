import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الشروط وسياسة الخصوصية')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            _LegalSection(
              title: 'الشروط والأحكام',
              text:
                  'باستخدام MedLink، تؤكد صحة بياناتك وتتعهد باستخدام التطبيق لطلب الأدوية والمنتجات الطبية بطريقة نظامية. تخضع الطلبات للتوفر والمراجعة والتوصيل حسب الفرع.',
            ),
            _LegalSection(
              title: 'الخصوصية',
              text:
                  'نستخدم بيانات الحساب والعناوين والطلبات لتشغيل الخدمة وتوصيل الطلبات وتحسين الدعم. لا يعرض التطبيق بياناتك لعملاء آخرين، وتخضع البيانات لسياسات قاعدة البيانات وصلاحيات الحساب.',
            ),
          ],
        ),
      );
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(text),
            ],
          ),
        ),
      );
}