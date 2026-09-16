import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = context.watch<AuthController>().profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        ClientCard(
          borderRadius: 28,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [ClientColors.primary, ClientColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ClientColors.primary.withValues(alpha: .35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (profile?.name?.trim().isNotEmpty == true
                            ? profile!.name!.trim()[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? l10n.clientProfileLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (profile?.email != null)
                      Text(
                        profile!.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AccountTile(
          icon: Icons.qr_code_2_rounded,
          title: l10n.digitalCardTitle,
          subtitle: l10n.digitalCardSubtitle,
          color: ClientColors.primary,
          onTap: () => context.push('/client/digital-card'),
        ),
        _AccountTile(
          icon: Icons.location_on_outlined,
          title: l10n.deliveryAddress,
          subtitle: l10n.manageDeliveryAddresses,
          color: ClientColors.success,
          onTap: () => context.push('/client/addresses'),
        ),
        _AccountTile(
          icon: Icons.notifications_outlined,
          title: l10n.notificationsTitle,
          subtitle: l10n.notificationsEmpty,
          color: ClientColors.primary,
          onTap: () => context.push('/notifications'),
        ),
        _AccountTile(
          icon: Icons.business_outlined,
          title: l10n.businessProfileTitle,
          subtitle: l10n.businessProfileSubtitle,
          color: ClientColors.primaryDark,
          onTap: () => context.push('/client/business-profile'),
        ),
        _AccountTile(
          icon: Icons.help_outline_rounded,
          title: l10n.helpSupportTitle,
          subtitle: l10n.helpContactSection,
          color: ClientColors.navy,
          onTap: () => context.push('/help', extra: profile?.role),
        ),
        _AccountTile(
          icon: Icons.policy_outlined,
          title: l10n.termsPrivacyTitle,
          subtitle: l10n.termsPrivacySubtitle,
          color: ClientColors.textMuted,
          onTap: () => context.push('/client/legal'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout_rounded),
          label: Text(l10n.logoutButton),
          style: FilledButton.styleFrom(
            backgroundColor: ClientColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Row(
          children: [
            ClientIconBadge(
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
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: ClientColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
