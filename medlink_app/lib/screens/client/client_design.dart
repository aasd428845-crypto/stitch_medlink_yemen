import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../branch_manager/branch_manager_design.dart';

/// Glass surface card for client screens — uses BranchColors tokens only.
/// Rule: NO raw Color() here; all tokens come from BranchColors / AppColors.
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
    return SoftCard(
      margin: margin,
      padding: padding,
      borderRadius: 24,
      child: child,
    );
  }
}

/// Gradient hero banner for the client role.
/// Uses the same glassHeroGradient (violet→pink→sky) as branch manager.
class ClientHero extends StatelessWidget {
  const ClientHero({super.key, required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير ☀️';
    if (h < 17) return 'مساء النشاط 💊';
    return 'مساء الخير 🌙';
  }

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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .09),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    Icon(Icons.verified_rounded,
                        size: 14, color: Colors.white),
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
                _greeting,
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
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: TextField(
            controller: controller,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              color: BranchColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'البحث في الأدوية والمنتجات',
              hintStyle:
                  TextStyle(color: BranchColors.onSurfaceVariant),
              prefixIcon: Icon(Icons.search_rounded,
                  color: BranchColors.primary),
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
              fillColor: Colors.white.withValues(alpha: .75),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 15, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                    color: BranchColors.outlineVariant
                        .withValues(alpha: .5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide:
                    BorderSide(color: BranchColors.primary, width: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
