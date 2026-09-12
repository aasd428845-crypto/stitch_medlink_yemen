import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';
import '../branch_manager/branch_manager_design.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
                  vertical: 30,
                ),
                borderRadius: 32,
                tint: .82,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 82),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'MedLink',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: BranchColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: BranchColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'جارٍ تجهيز تجربتك',
                      style: Theme.of(context).textTheme.bodySmall,
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
