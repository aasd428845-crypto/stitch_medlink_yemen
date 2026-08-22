import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../utils/theme.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات منشأتي')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Icon(Icons.business_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'الاسم', value: profile?.name ?? '—'),
          _InfoRow(label: 'البريد الإلكتروني', value: profile?.email ?? '—'),
          _InfoRow(label: 'رقم الهاتف', value: profile?.phone ?? '—'),
          _InfoRow(label: 'الفرع المرتبط', value: profile?.branchName ?? 'غير محدد'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'تُدار بيانات الحساب الأساسية من خلال الملف المسجل في النظام.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(title: Text(label), subtitle: Text(value)),
      );
}