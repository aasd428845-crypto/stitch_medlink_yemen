import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ClientColors.text,
          title: Text(l10n.businessProfileTitle),
        ),
        body: ClientGlassBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ClientCard(
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
                          colors: [
                            ClientColors.primary,
                            ClientColors.navy,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ClientColors.primary.withValues(alpha: .35),
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
              _InfoRow(icon: Icons.person_outline, label: l10n.nameLabel, value: profile?.name ?? '—', color: ClientColors.primary),
              _InfoRow(icon: Icons.email_outlined, label: l10n.emailLabel, value: profile?.email ?? '—', color: ClientColors.primaryDark),
              _InfoRow(icon: Icons.phone_outlined, label: l10n.phoneLabel, value: profile?.phone ?? '—', color: ClientColors.success),
              _InfoRow(icon: Icons.store_outlined, label: l10n.linkedBranchLabel, value: profile?.branchName ?? l10n.notAvailableLabel, color: ClientColors.navy),
              const SizedBox(height: 16),
              ClientCard(
                borderRadius: 20,
                child: Text(
                  l10n.businessProfileNote,
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
    return ClientCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: Row(
        children: [
          ClientIconBadge(icon: icon, color: color, size: 44, iconSize: 20, borderRadius: 14),
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