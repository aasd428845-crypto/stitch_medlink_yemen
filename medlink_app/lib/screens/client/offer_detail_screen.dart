import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/promotional_offer.dart';
import '../../utils/theme.dart';

/// Full-page detail view for a promotional offer.
/// Receives the [PromotionalOffer] via GoRouter's `extra` parameter.
class OfferDetailScreen extends StatelessWidget {
  const OfferDetailScreen({super.key, required this.offer});

  final PromotionalOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image / gradient app bar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: offer.imageUrl != null
                  ? Image.network(
                      offer.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientHero(),
                    )
                  : _gradientHero(),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount badge
                  if (offer.discountText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        offer.discountText!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Title
                  Text(
                    offer.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Description
                  if (offer.description != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      offer.description!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Validity period
                  if (offer.startDate != null || offer.endDate != null) ...[
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.offerValidFrom,
                      value: _formatDate(offer.startDate),
                    ),
                    if (offer.endDate != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.event_outlined,
                        label: l10n.offerValidUntil,
                        value: _formatDate(offer.endDate),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Target governorate
                  if (offer.targetGovernorate != null) ...[
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: l10n.offerGovernorate,
                      value: offer.targetGovernorate!,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientHero() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primaryContainer, AppColors.primary],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
