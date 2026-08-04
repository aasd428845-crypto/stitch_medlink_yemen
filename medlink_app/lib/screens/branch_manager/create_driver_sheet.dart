import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';

/// Modal bottom sheet that lets a branch manager create a new driver account.
/// On success it shows the credentials the manager should share with the
/// driver, then closes and refreshes the drivers list.
class CreateDriverSheet extends StatefulWidget {
  const CreateDriverSheet({super.key});

  @override
  State<CreateDriverSheet> createState() => _CreateDriverSheetState();
}

class _CreateDriverSheetState extends State<CreateDriverSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<BranchController>().createDriver(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            tempPassword: _passwordCtrl.text.trim(),
          );
      if (!mounted) return;
      _showSuccessDialog(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog({required String email, required String password}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
        title: Text(l10n.driverCreatedSuccess),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.driverCreatedMessage),
            const SizedBox(height: AppSpacing.md),
            _CredentialRow(label: l10n.emailLabel, value: email),
            const SizedBox(height: AppSpacing.xs),
            _CredentialRow(
                label: l10n.driverTempPasswordLabel, value: password),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // close the sheet
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.driverCreateTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
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
            AppTextField(
              label: l10n.nameLabel,
              controller: _nameCtrl,
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.validationRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.emailLabel,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.validationRequired;
                if (!v.contains('@')) return l10n.validationEmailInvalid;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.phoneLabel,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.driverTempPasswordLabel,
              controller: _passwordCtrl,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.validationRequired;
                if (v.trim().length < 6) return l10n.validationPasswordShort;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: l10n.driverCreateButton,
              onPressed: _submit,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
