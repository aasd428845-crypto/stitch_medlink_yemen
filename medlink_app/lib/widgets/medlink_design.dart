import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Shared background treatment for every role: deep navy with restrained
/// cyan/violet light pools behind the content.
class MedLinkBackground extends StatelessWidget {
  const MedLinkBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.deepNavy,
            AppColors.midnightNavy,
            Color(0xFF06101F),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -130,
            right: -80,
            child: _Glow(color: AppColors.primary, size: 280),
          ),
          Positioned(
            top: 260,
            left: -170,
            child: _Glow(color: AppColors.violet, size: 330),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.08),
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLow.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.92),
        ),
      ),
      child: child,
    );
  }
}

class MedLinkScaffold extends StatelessWidget {
  const MedLinkScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: appBar,
      backgroundColor: Colors.transparent,
      body: MedLinkBackground(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

class MedLinkTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MedLinkTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }
}

class MedLinkBottomNav extends StatelessWidget {
  const MedLinkBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'مسح البحث',
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}
