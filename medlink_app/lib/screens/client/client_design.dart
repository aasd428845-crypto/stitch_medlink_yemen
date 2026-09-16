import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/theme.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.tint = .92,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: ClientColors.surface.withValues(alpha: tint.clamp(0, 1)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: ClientColors.outline),
        boxShadow: [
          BoxShadow(
            color: ClientColors.navy.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ClientIconBadge extends StatelessWidget {
  const ClientIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 20,
    this.borderRadius = 14,
    this.shape = BoxShape.rectangle,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
        shape: shape,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class ClientSectionTitle extends StatelessWidget {
  const ClientSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor = ClientColors.primary,
    this.action,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClientIconBadge(icon: icon, color: iconColor, size: 34, iconSize: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ClientColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: ClientColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

/// Surface card for client screens — uses the clinical client tokens.
class ClientDesignSurface extends StatelessWidget {
  const ClientDesignSurface({
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
    return ClientCard(
      margin: margin,
      padding: padding,
      borderRadius: 24,
      child: child,
    );
  }
}

class ClientFloatingBottomBar extends StatelessWidget {
  const ClientFloatingBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.onFabPressed,
    this.fabIcon = LucideIcons.shoppingCart,
  });

  final List<ClientBottomBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onFabPressed;
  final IconData fabIcon;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    final mid = (items.length / 2).ceil();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: ClientColors.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: ClientColors.outline),
              boxShadow: [
                BoxShadow(
                  color: ClientColors.navy.withValues(alpha: .10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < mid; i++)
                  _ClientBarItem(
                    item: items[i],
                    selected: selectedIndex == i,
                    showLabel: isWide,
                    onTap: () => onSelect(i),
                  ),
                _ClientFab(onPressed: onFabPressed, icon: fabIcon),
                for (var i = mid; i < items.length; i++)
                  _ClientBarItem(
                    item: items[i],
                    selected: selectedIndex == i,
                    showLabel: isWide,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClientBottomBarItem {
  const ClientBottomBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _ClientFab extends StatelessWidget {
  const _ClientFab({required this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: ClientColors.primary,
          foregroundColor: Colors.white,
          fixedSize: const Size(56, 56),
          shape: const CircleBorder(),
        ),
        icon: Icon(icon, size: 24),
      ),
    );
  }
}

class _ClientBarItem extends StatelessWidget {
  const _ClientBarItem({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final ClientBottomBarItem item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? ClientColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: selected ? ClientColors.primary : ClientColors.textMuted,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 16 : 4,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? ClientColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  color: selected
                      ? ClientColors.primary
                      : ClientColors.textMuted,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Calm clinical background used by client detail flows outside the home shell.
class ClientGlassBackground extends StatelessWidget {
  const ClientGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ClientColors.surface, ClientColors.background],
        ),
      ),
      child: child,
    );
  }
}

/// Trustworthy hero banner for the client role.
class ClientHero extends StatelessWidget {
  const ClientHero({
    super.key,
    required this.name,
    required this.subtitle,
    required this.greeting,
  });

  final String name;
  final String subtitle;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.0, 0.5, 1.0],
          colors: [
            ClientColors.primaryDark,
            ClientColors.primary,
            ClientColors.navy,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ClientColors.navy.withValues(alpha: .14),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .20),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: Colors.white.withValues(alpha: .30),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'MedLink',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            greeting,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: .80),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search field styled for the light glass design.
class ClientSearchField extends StatelessWidget {
  const ClientSearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onChanged,
    this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: ClientColors.text, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: ClientColors.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: ClientColors.primary),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onSubmitted('');
                  },
                ),
          filled: true,
          fillColor: ClientColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: ClientColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: ClientColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}
