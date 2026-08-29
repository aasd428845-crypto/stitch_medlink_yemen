import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/theme.dart';

/// Modern floating glass bottom navigation bar used by the branch manager
/// shell. A frosted pill floated above the bottom edge with a central warm
/// gradient FAB for quick actions.
///
/// Wide layouts (>840) show the FAB between two labelled clusters; compact
/// layouts show icon-only items packed around the FAB.
class BranchFloatingBottomBar extends StatelessWidget {
  const BranchFloatingBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.onFabPressed,
    this.fabIcon = LucideIcons.plus,
  });

  final List<BranchBottomBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onFabPressed;
  final IconData fabIcon;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 840;
    // Split around the FAB.
    final mid = (items.length / 2).ceil();
    final leftItems = items.take(mid).toList();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BranchColors.glassSurface.withValues(alpha: .66),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: BranchColors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < leftItems.length; i++)
                  _BarItem(
                    item: leftItems[i],
                    index: i,
                    selected: selectedIndex == i,
                    onTap: () => onSelect(i),
                    showLabel: isWide,
                  ),
                _CentralFab(onPressed: onFabPressed, icon: fabIcon),
                for (var i = mid; i < items.length; i++)
                  _BarItem(
                    item: items[i],
                    index: i,
                    selected: selectedIndex == i,
                    onTap: () => onSelect(i),
                    showLabel: isWide,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CentralFab extends StatelessWidget {
  const _CentralFab({required this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: BranchColors.glassWarmGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: BranchColors.glassWarmGradient.first.withValues(alpha: .5),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: BranchColors.onPrimary, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.showLabel,
  });

  final BranchBottomBarItem item;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? BranchColors.primary : BranchColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.symmetric(horizontal: showLabel ? 10 : 6, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? BranchColors.primaryContainer.withValues(alpha: .14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 20),
            if (showLabel) ...[
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single destination in the floating bar.
class BranchBottomBarItem {
  const BranchBottomBarItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
