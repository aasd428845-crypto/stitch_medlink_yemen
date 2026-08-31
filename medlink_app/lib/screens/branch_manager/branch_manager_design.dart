import 'dart:ui';

import 'package:flutter/material.dart';


import '../../utils/theme.dart';

/// Shared Modern Glassmorphism design widgets for every branch-manager screen.
///
/// Rule: this file must NEVER define a raw `Color(0x…)` — all colors come from
/// the central tokens in BranchColors / AppTheme.branchManagerLight.

// ─── Background ───────────────────────────────────────────────────────────────

/// Soft pastel gradient + floating decorative orbs behind all branch content.
/// Place this behind a [Scaffold]'s body so the glass blur reads correctly.
class BranchGlassBackground extends StatelessWidget {
  const BranchGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
          colors: [
            BranchColors.glassBackgroundStart,
            Color(0xFFEFF0FF),
            BranchColors.glassBackgroundEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -70,
            child: _Orb(size: 260, color: BranchColors.orbSky),
          ),
          const Positioned(
            top: 160,
            left: -80,
            child: _Orb(size: 220, color: BranchColors.orbMint),
          ),
          const Positioned(
            top: 380,
            right: -60,
            child: _Orb(size: 200, color: BranchColors.orbPink),
          ),
          const Positioned(
            bottom: 120,
            left: -70,
            child: _Orb(size: 220, color: BranchColors.orbViolet),
          ),
          const Positioned(
            bottom: 280,
            right: 50,
            child: _Orb(size: 150, color: BranchColors.orbPeach),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

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
          colors: [color.withValues(alpha: .85), color.withValues(alpha: 0)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .28),
            blurRadius: 80,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

// ─── Glass Cards ──────────────────────────────────────────────────────────────

/// True frosted-glass card — BackdropFilter blur + translucent white fill +
/// soft white border + faint drop shadow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.blur = 16,
    this.tint = 0.72,
    this.borderOpacity = 0.4,
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
                  color: Colors.white.withValues(alpha: borderOpacity),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 24,
                  spreadRadius: 0,
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

/// Soft glass wrap — milder blur for flat pastel zones.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.blur = 12,
    this.tint = 0.72,
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
                  color: Colors.white.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
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

/// Backwards-compatible surface used across existing branch screens —
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

// ─── Icon Badge ───────────────────────────────────────────────────────────────

/// A rounded square / circle with a soft tinted fill — the pastel icon badge.
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
    this.gradient,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final BoxShape shape;
  final double borderRadius;
  final Color? backgroundColor;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradient == null
            ? (backgroundColor ?? color.withValues(alpha: .14))
            : null,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: gradient!.first.withValues(alpha: .35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Icon(icon,
          color: gradient != null ? Colors.white : color, size: iconSize),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

/// The full-bleed gradient hero header for the branch dashboard.
/// Violet → Pink → Sky blue, with a greeting, branch status badge, and
/// decorative overlay circles.
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

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير ☀️';
    if (h < 17) return 'مساء النشاط 💼';
    return 'مساء الخير 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 0.5, 1.0],
          colors: BranchColors.glassHeroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: BranchColors.glassHeroGradient.first.withValues(alpha: .35),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative overlay circles
          Positioned(
            top: -40,
            left: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .10),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status badge + optional trailing
              Row(
                children: [
                  _AnimatedStatusBadge(),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 18),
              // Greeting
              Text(
                _greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: .85),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              // Main title
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: .80),
                      height: 1.6,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatusBadge extends StatefulWidget {
  @override
  State<_AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<_AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .20),
        borderRadius: BorderRadius.circular(99),
        border:
            Border.all(color: Colors.white.withValues(alpha: .30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6EE7B7),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6EE7B7).withValues(alpha: .6),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'الفرع يعمل',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metric Tile ──────────────────────────────────────────────────────────────

/// A stat tile with a coloured accent header strip and large value.
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

  List<Color> get _gradient {
    if (color == BranchColors.warning) return BranchColors.metricOrangeGradient;
    if (color == BranchColors.success) return BranchColors.metricGreenGradient;
    if (color == BranchColors.primaryContainer) {
      return BranchColors.metricPurpleGradient;
    }
    return BranchColors.metricBlueGradient;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .75),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withValues(alpha: .5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _gradient.first.withValues(alpha: .12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent top strip with icon
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ),
              ),
              // Value + label
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          value,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: BranchColors.onSurface,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: BranchColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
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
}

// ─── Quick Action ─────────────────────────────────────────────────────────────

/// A quick-action chip with a gradient icon container and press animation.
class BranchQuickAction extends StatefulWidget {
  const BranchQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final List<Color>? gradient;

  @override
  State<BranchQuickAction> createState() => _BranchQuickActionState();
}

class _BranchQuickActionState extends State<BranchQuickAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grad = widget.gradient;

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withValues(alpha: .5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: (grad?.first ?? widget.color).withValues(alpha: .12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient icon container
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: grad != null
                          ? LinearGradient(
                              colors: grad,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color:
                          grad == null ? widget.color.withValues(alpha: .14) : null,
                      boxShadow: grad != null
                          ? [
                              BoxShadow(
                                color: grad.first.withValues(alpha: .38),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.icon,
                      color: grad != null ? Colors.white : widget.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: BranchColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

/// Section heading with a vibrant accent bar.
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
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: BranchColors.glassHeroGradient,
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? BranchColors.onSurfaceVariant, size: 18),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BranchColors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: BranchColors.glassHeroGradient.first,
              textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}
