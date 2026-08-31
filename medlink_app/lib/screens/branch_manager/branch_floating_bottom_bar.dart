import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/theme.dart';

/// Modern floating glass bottom navigation bar for the branch manager shell.
///
/// A frosted pill floated above the bottom edge, with:
/// - BackdropFilter blur (sigmaX: 30) for deep glass effect
/// - AnimatedScale on selected items
/// - Gradient-coloured indicator dot under the selected icon
/// - Central warm gradient FAB for quick actions
/// - Wide layout (>840) shows labels; compact shows icon-only
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
    final mid = (items.length / 2).ceil();
    final leftItems = items.take(mid).toList();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: Colors.white.withValues(alpha: .55), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: BranchColors.glassHeroGradient.first
                      .withValues(alpha: .08),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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

// ─── Central FAB ─────────────────────────────────────────────────────────────

class _CentralFab extends StatefulWidget {
  const _CentralFab({required this.onPressed, required this.icon});

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  State<_CentralFab> createState() => _CentralFabState();
}

class _CentralFabState extends State<_CentralFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.88,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onPressed?.call();
        },
        onTapCancel: () => _ctrl.forward(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: BranchColors.glassWarmGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: BranchColors.glassWarmGradient.first
                      .withValues(alpha: .55),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(LucideIcons.plus,
                color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

// ─── Bar Item ─────────────────────────────────────────────────────────────────

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding:
            EdgeInsets.symmetric(horizontal: showLabel ? 12 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? BranchColors.glassHeroGradient.first.withValues(alpha: .10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              child: Icon(
                item.icon,
                color: selected
                    ? BranchColors.glassHeroGradient.first
                    : BranchColors.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            // Indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              width: selected ? 16 : 4,
              height: 3,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: BranchColors.glassHeroGradient,
                      )
                    : null,
                color: selected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: selected
                      ? BranchColors.glassHeroGradient.first
                      : BranchColors.onSurfaceVariant,
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 10,
                ),
                child: Text(item.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Data Class ───────────────────────────────────────────────────────────────

/// A single destination in the floating bar.
class BranchBottomBarItem {
  const BranchBottomBarItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
