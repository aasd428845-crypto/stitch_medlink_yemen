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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;
    if (!_acceptedTerms) {
      setState(() => _errorMessage = l10n.validationTermsRequired);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final authService = context.read<AuthService>();
      await authService.signUpClient(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      try {
        await authService.acceptTerms();
      } catch (_) {}
      if (!mounted) return;
      await context.read<AuthController>().refreshProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = mapAuthErrorToMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: BranchColors.onSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/login'),
          ),
        ),
        body: BranchGlassBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          const Center(child: AppLogo(size: 56)),
                          const SizedBox(height: 16),
                          Text(
                            l10n.registerTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.registerSubtitle,
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
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.nameLabel,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.emailLabel,
                              prefixIcon: const Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.phoneLabel,
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: l10n.confirmPasswordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                activeColor: BranchColors.primary,
                                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                              ),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text('${l10n.acceptTermsPrefix} '),
                                    GestureDetector(
                                      onTap: () => context.push('/terms'),
                                      child: Text(
                                        l10n.termsAndConditions,
                                        style: const TextStyle(
                                          color: BranchColors.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                    l10n.registerButton,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.alreadyHaveAccount),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: Text(l10n.loginLink),
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

