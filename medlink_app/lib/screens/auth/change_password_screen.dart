import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/driver_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';

/// Forced password-change screen for drivers whose account has
/// [requiresPasswordChange] = true (first login after manager creation or
/// after a manager-triggered password reset). The driver cannot navigate
/// anywhere else until they set a new password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final driverService = context.read<DriverService>();
      await driverService.changeMyPassword(_newPasswordCtrl.text.trim());
      if (!mounted) return;
      // Refresh the profile so requiresPasswordChange becomes false and
      // GoRouter redirect carries the driver to /driver.
      await context.read<AuthController>().refreshProfile();
      if (!mounted) return;
      context.go('/driver');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Icon(
                  Icons.lock_reset_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.changePasswordTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.changePasswordSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  label: l10n.newPasswordLabel,
                  controller: _newPasswordCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
                    if (v.trim().length < 6) return l10n.validationPasswordShort;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.confirmNewPasswordLabel,
                  controller: _confirmCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
                    if (v.trim() != _newPasswordCtrl.text.trim()) {
                      return l10n.validationPasswordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: l10n.changePasswordButton,
                  onPressed: _submit,
                  isLoading: _loading,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.logoutButton),
                  onPressed: () => context.read<AuthController>().signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
