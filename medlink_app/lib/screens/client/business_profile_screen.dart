import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../utils/theme.dart';
import '../branch_manager/branch_manager_design.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: BranchColors.onSurface,
          title: const Text('بيانات منشأتي'),
        ),
        body: BranchGlassBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              GlassCard(
                borderRadius: 28,
                tint: 0.78,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: BranchColors.glassHeroGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BranchColors.glassHeroGradient.first.withValues(alpha: .35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(profile?.name ?? '—', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(profile?.email ?? '—', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.person_outline, label: 'الاسم', value: profile?.name ?? '—', color: BranchColors.primary),
              _InfoRow(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: profile?.email ?? '—', color: BranchColors.primaryContainer),
              _InfoRow(icon: Icons.phone_outlined, label: 'رقم الهاتف', value: profile?.phone ?? '—', color: BranchColors.success),
              _InfoRow(icon: Icons.store_outlined, label: 'الفرع المرتبط', value: profile?.branchName ?? 'غير محدد', color: BranchColors.warning),
              const SizedBox(height: 16),
              SoftCard(
                borderRadius: 20,
                child: Text(
                  'تُدار بيانات الحساب الأساسية من خلال الملف المسجل في النظام.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: Row(
        children: [
          PastelIconBadge(icon: icon, color: color, size: 44, iconSize: 20, borderRadius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}