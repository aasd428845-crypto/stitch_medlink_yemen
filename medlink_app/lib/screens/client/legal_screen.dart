import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          backgroundColor: ClientColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: ClientColors.text,
          title: Text(l10n.termsPrivacyTitle),
        ),
        body: ClientGlassBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _LegalSection(
                icon: Icons.gavel_rounded,
                color: ClientColors.primary,
                title: l10n.termsSectionTitle,
                text: l10n.termsSectionBody,
              ),
              const SizedBox(height: 12),
              _LegalSection(
                icon: Icons.shield_outlined,
                color: ClientColors.success,
                title: l10n.privacySectionTitle,
                text: l10n.privacySectionBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClientIconBadge(
                icon: icon,
                color: color,
                size: 40,
                iconSize: 20,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}
