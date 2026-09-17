import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/promotional_offer.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

class OfferDetailScreen extends StatelessWidget {
  const OfferDetailScreen({super.key, required this.offer});
  final PromotionalOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ClientGlassBackground(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.transparent,
                foregroundColor: ClientColors.text,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (offer.discountText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                ClientColors.primary,
                                ClientColors.primaryDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: ClientColors.primary.withValues(
                                  alpha: .35,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            offer.discountText!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        offer.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (offer.description != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          offer.description!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: ClientColors.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Divider(
                        color: ClientColors.outline.withValues(alpha: .5),
                      ),
                      const SizedBox(height: 16),
                      if (offer.startDate != null || offer.endDate != null) ...[
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.offerValidFrom,
                          value: _formatDate(offer.startDate),
                          color: ClientColors.primary,
                        ),
                        if (offer.endDate != null) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.event_outlined,
                            label: l10n.offerValidUntil,
                            value: _formatDate(offer.endDate),
                            color: ClientColors.primaryDark,
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      if (offer.targetGovernorate != null) ...[
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: l10n.offerGovernorate,
                          value: offer.targetGovernorate!,
                          color: ClientColors.success,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientHero() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [ClientColors.primaryDark, ClientColors.navy],
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
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClientIconBadge(
            icon: icon,
            color: color,
            size: 40,
            iconSize: 18,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
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
