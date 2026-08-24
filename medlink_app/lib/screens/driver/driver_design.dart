import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';

class DriverSurface extends StatelessWidget {
  const DriverSurface({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.outlineVariant),
      boxShadow: [BoxShadow(color: AppColors.midnightNavy.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: child,
  );
}

class DriverHero extends StatelessWidget {
  const DriverHero({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [AppColors.deepBlue, AppColors.deepNavy, AppColors.midnightNavy],
      ),
      border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
    ),
    child: Stack(children: [
      Positioned(right: -55, top: -70, child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: .13))))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .13), borderRadius: BorderRadius.circular(AppRadius.full)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.local_shipping_rounded, size: 14, color: AppColors.primary), const SizedBox(width: 6), Text(AppLocalizations.of(context)!.driverRoleLabel, style: TextStyle(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 12))])),
        const SizedBox(height: 14),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.onSurface, fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.45)),
      ]),
    ]),
  );
}
