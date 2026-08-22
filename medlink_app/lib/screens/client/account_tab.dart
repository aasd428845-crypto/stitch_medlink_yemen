import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

/// The client's account hub. Each row is intentionally routed to a real
/// screen or service; no placeholder actions are presented as complete.
class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<AuthController>().profile;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    (profile?.name?.trim().isNotEmpty == true
                            ? profile!.name!.trim()[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.onPrimaryContainer,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.name ?? l10n.clientProfileLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (profile?.email != null)
                        Text(
                          profile!.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AccountTile(
          icon: Icons.qr_code_2_rounded,
          title: 'بطاقتي الرقمية',
          subtitle: 'بيانات العميل ورمز QR',
          onTap: () => context.push('/client/digital-card'),
        ),
        _AccountTile(
          icon: Icons.location_on_outlined,
          title: l10n.deliveryAddress,
          subtitle: 'إدارة عناوين التوصيل',
          onTap: () => context.push('/client/addresses'),
        ),
        _AccountTile(
          icon: Icons.notifications_outlined,
          title: l10n.notificationsTitle,
          subtitle: l10n.notificationsEmpty,
          onTap: () => context.push('/notifications'),
        ),
        _AccountTile(
          icon: Icons.business_outlined,
          title: 'بيانات منشأتي',
          subtitle: 'البيانات المسجلة في الحساب',
          onTap: () => context.push('/client/business-profile'),
        ),
        _AccountTile(
          icon: Icons.help_outline_rounded,
          title: l10n.helpSupportTitle,
          subtitle: l10n.helpContactSection,
          onTap: () => context.push('/help', extra: profile?.role),
        ),
        _AccountTile(
          icon: Icons.policy_outlined,
          title: 'الشروط وسياسة الخصوصية',
          subtitle: 'راجع أحكام استخدام MedLink',
          onTap: () => context.push('/client/legal'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout_rounded),
          label: Text(l10n.logoutButton),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthService>().signOut();
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }
}