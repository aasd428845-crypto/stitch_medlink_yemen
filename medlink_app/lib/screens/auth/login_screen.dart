import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../utils/error_mapper.dart';
import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/error_banner.dart';
import '../branch_manager/branch_manager_design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      await context.read<AuthController>().refreshProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = mapAuthErrorToMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isGoogleSubmitting = true;
      _errorMessage = null;
    });
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();
      if (!mounted) return;
      await context.read<AuthController>().refreshProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = mapAuthErrorToMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BranchGlassBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: GlassCard(
                    padding: const EdgeInsets.all(28),
                    borderRadius: 32,
                    tint: 0.78,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: AppLogo()),
                          const SizedBox(height: 16),
                          Text(
                            l10n.appName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: BranchColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            l10n.loginTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.loginSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BranchColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) ...[
                            ErrorBanner(message: _errorMessage!),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: l10n.emailLabel,
                              prefixIcon: const Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(l10n.forgotPassword),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: BranchColors.primaryContainer,
                              foregroundColor: BranchColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: BranchColors.onPrimary,
                                    ),
                                  )
                                : Text(
                                    l10n.loginButton,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  l10n.orDivider,
                                  style: const TextStyle(color: BranchColors.onSurfaceVariant),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _isGoogleSubmitting ? null : _submitGoogle,
                            icon: _isGoogleSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.g_mobiledata, size: 26),
                            label: Text(l10n.continueWithGoogle),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: BranchColors.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.noAccountYet),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: Text(l10n.createAccountLink),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

