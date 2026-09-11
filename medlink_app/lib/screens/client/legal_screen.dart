import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../branch_manager/branch_manager_design.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: BranchColors.onSurface,
          title: const Text('الشروط وسياسة الخصوصية'),
        ),
        body: BranchGlassBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _LegalSection(
                icon: Icons.gavel_rounded,
                color: BranchColors.primary,
                title: 'الشروط والأحكام',
                text: 'باستخدام MedLink، تؤكد صحة بياناتك وتتعهد باستخدام التطبيق لطلب الأدوية والمنتجات الطبية بطريقة نظامية. تخضع الطلبات للتوفر والمراجعة والتوصيل حسب الفرع.',
              ),
              const SizedBox(height: 12),
              _LegalSection(
                icon: Icons.shield_outlined,
                color: BranchColors.success,
                title: 'الخصوصية',
                text: 'نستخدم بيانات الحساب والعناوين والطلبات لتشغيل الخدمة وتوصيل الطلبات وتحسين الدعم. لا يعرض التطبيق بياناتك لعملاء آخرين، وتخضع البيانات لسياسات قاعدة البيانات وصلاحيات الحساب.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.icon, required this.color, required this.title, required this.text});
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PastelIconBadge(icon: icon, color: color, size: 40, iconSize: 20, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: 14),
          Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7)),
        ],
      ),
    );
  }
}