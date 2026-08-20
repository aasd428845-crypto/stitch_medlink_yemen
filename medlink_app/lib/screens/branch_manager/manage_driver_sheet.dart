import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/branch_controller.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';

/// Bottom sheet for managing an existing driver: activate/suspend account and
/// reset password. The branch manager stays signed in throughout.
class ManageDriverSheet extends StatefulWidget {
  const ManageDriverSheet({super.key, required this.driver});

  final UserProfile driver;

  @override
  State<ManageDriverSheet> createState() => _ManageDriverSheetState();
}

class _ManageDriverSheetState extends State<ManageDriverSheet> {
  String? _error;
  bool _loadingStatus = false;

  // password-reset sub-section
  bool _showReset = false;
  final _resetFormKey = GlobalKey<FormState>();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loadingReset = false;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus() async {
    final newStatus =
        widget.driver.accountStatus == AccountStatus.active ? 'suspended' : 'active';
    setState(() {
      _loadingStatus = true;
      _error = null;
    });
    try {
      await context
          .read<BranchController>()
          .updateDriverStatus(widget.driver.id, newStatus);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _submitResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _loadingReset = true;
      _error = null;
    });
    try {
      await context.read<BranchController>().resetDriverPassword(
            widget.driver.id,
            _newPasswordCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.driverActionSuccess),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driver = widget.driver;
    final isActive = driver.accountStatus == AccountStatus.active;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isActive ? BranchColors.successContainer : BranchColors.warningContainer,
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: isActive ? BranchColors.success : BranchColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name?.isNotEmpty == true
                          ? driver.name!
                          : driver.email,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      driver.phone ?? driver.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: driver.accountStatus),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Activate / Suspend ──────────────────────────────────────────
          OutlinedButton.icon(
            icon: Icon(
              isActive ? Icons.pause_circle_outline : Icons.check_circle_outline,
              color: isActive ? BranchColors.warning : BranchColors.success,
            ),
            label: Text(
              isActive ? l10n.driverSuspend : l10n.driverActivate,
              style: TextStyle(
                color: isActive ? BranchColors.warning : BranchColors.success,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isActive ? BranchColors.warning : BranchColors.success,
              ),
            ),
            onPressed: _loadingStatus ? null : _toggleStatus,
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Reset Password ──────────────────────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset_rounded),
            label: Text(l10n.driverResetPassword),
            onPressed: () => setState(() => _showReset = !_showReset),
          ),

          if (_showReset) ...[
            const SizedBox(height: AppSpacing.md),
            Form(
              key: _resetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: l10n.driverResetPasswordNew,
                    controller: _newPasswordCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.validationRequired;
                      }
                      if (v.trim().length < 6) {
                        return l10n.validationPasswordShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.driverResetPasswordConfirm,
                    controller: _confirmCtrl,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.validationRequired;
                      }
                      if (v.trim() != _newPasswordCtrl.text.trim()) {
                        return l10n.validationPasswordMismatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    label: l10n.driverResetPassword,
                    onPressed: _submitResetPassword,
                    isLoading: _loadingReset,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (status) {
      AccountStatus.active => (
          l10n.driverStatusActive,
          BranchColors.successContainer,
          BranchColors.success,
        ),
      AccountStatus.suspended => (
          l10n.driverStatusSuspended,
          BranchColors.warningContainer,
          BranchColors.warning,
        ),
      _ => (
          l10n.driverStatusPending,
          BranchColors.secondaryContainer,
          BranchColors.secondary,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
