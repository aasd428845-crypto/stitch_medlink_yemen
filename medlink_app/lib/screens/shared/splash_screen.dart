import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';
import '../branch_manager/branch_manager_design.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BranchGlassBackground(
          child: SafeArea(
            child: Center(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 34,
                  vertical: 32,
                ),
                borderRadius: 32,
                tint: .82,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: BranchColors.primary.withValues(
                                alpha: .14 + (_controller.value * .12),
                              ),
                              blurRadius: 22,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: const AppLogo(size: 82),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'MedLink',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: BranchColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: const AlwaysStoppedAnimation(
                          BranchColors.primary,
                        ),
                        backgroundColor: BranchColors.primary.withValues(
                          alpha: .15,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'جارٍ تجهيز تجربتك',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
