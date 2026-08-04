import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../utils/theme.dart';

/// Placeholder body used by role home screens for sections not yet built in
/// this batch. Each role screen still owns its real bottom navigation so the
/// shell and routing are final — only the tab content is a stub for now.
class ComingSoonBody extends StatelessWidget {
  const ComingSoonBody({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded, size: 48, color: AppColors.outline),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.comingSoon,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class RoleAppBarActions extends StatelessWidget {
  const RoleAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => context.read<AuthController>().signOut(),
    );
  }
}
