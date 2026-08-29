import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/theme.dart';

/// Shared light glass widgets for every branch-manager screen (Modern
/// Glassmorphism UI).
///
/// Rule: this file must never define a `Color(0xâ€¦)` â€” all colors come from
/// the central tokens (BranchColors / AppTheme.branchManagerLight).

/// The soft pastel gradient + floating decorative orbs behind all branch
/// content. Place this behind a [Scaffold]'s body so the glass blur reads.
class BranchGlassBackground extends StatelessWidget {
  const BranchGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BranchColors.glassBackgroundStart,
            BranchColors.glassBackgroundEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -80,
            right: -60,
            child: _Blob(size: 220, color: BranchColors.orbSky),
          ),
          const Positioned(
            top: 140,
            left: -70,
            child: _Blob(size: 200, color: BranchColors.orbMint),
          ),
          const Positioned(
            top: 360,
            right: -50,
            child: _Blob(size: 180, color: BranchColors.orbPink),
          ),
          const Positioned(
            bottom: 90,
            left: -60,
            child: _Blob(size: 200, color: BranchColors.orbViolet),
          ),
          const Positioned(
            bottom: 240,
            right: 60,
            child: _Blob(size: 140, color: BranchColors.orbPeach),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .9), color.withValues(alpha: 0)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .35),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// A frosted-glass container used across every branch screen. Real
/// glassmorphism: a [BackdropFilter] blur with a translucent white fill and a
/// soft white border, finished with a faint drop shadow for depth.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.blur = 10,
    this.tint = 0.2,
    this.borderOpacity = 0.3,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double tint;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: tint),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                  color: Colors.white.withValues(alpha: borderOpacity)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Soft glass wrap — a gentler frosted card (milder blur) useful over flat
/// pastel zones and dense bento cells. Shares the same white-tint glass tokens.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.blur = 10,
    this.tint = 0.2,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: tint),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A rounded square/circle holding a lucide icon with a soft tinted fill â€”
/// the "pastel icon container" of the glass system.
class PastelIconBadge extends StatelessWidget {
  const PastelIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize = 20,
    this.shape = BoxShape.rectangle,
    this.borderRadius = 13,
    this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final BoxShape shape;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: .14),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Backwards-compatible surface used across existing branch screens â€” now
/// rendered as a soft glass card with no hard border.
class BranchManagerSurface extends StatelessWidget {
  const BranchManagerSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: margin,
      padding: padding,
      borderRadius: 24,
      child: child,
    );
  }
}

/// The hero gradient header of the branch area, retuned to a soft warm/pastel
/// glass feel.
class BranchManagerHero extends StatelessWidget {
  const BranchManagerHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: BranchColors.glassWarmGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: BranchColors.glassWarmGradient.first.withValues(alpha: .28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: 60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(children: [
                      Icon(LucideIcons.circle,
                          size: 8, color: BranchColors.onPrimary),
                      SizedBox(width: 6),
                      Text(
                        'الفرع يعمل بشكل طبيعي',
                        style: TextStyle(
                          color: BranchColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BranchColors.onPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BranchColors.onPrimary.withValues(alpha: .9),
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A stat tile on the glass dashboard.
class BranchMetricTile extends StatelessWidget {
  const BranchMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BranchManagerSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PastelIconBadge(
              icon: icon,
              color: color,
              shape: BoxShape.circle,
              size: 40,
              iconSize: 19),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BranchColors.onSurface,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: BranchColors.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quick-action chip with a pastel icon container.
class BranchQuickAction extends StatelessWidget {
  const BranchQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          borderRadius: 22,
          tint: .55,
          child: Column(
            children: [
              PastelIconBadge(
                  icon: icon,
                  color: color,
                  shape: BoxShape.circle,
                  size: 42,
                  iconSize: 19),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BranchColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section heading with a pastel accent bar.
class BranchSectionTitle extends StatelessWidget {
  const BranchSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [BranchColors.primaryContainer, BranchColors.primary],
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? BranchColors.onSurfaceVariant, size: 20),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BranchColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}
