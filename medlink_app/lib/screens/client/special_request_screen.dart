import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/order_controller.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

class SpecialRequestScreen extends StatefulWidget {
  const SpecialRequestScreen({super.key});

  @override
  State<SpecialRequestScreen> createState() => _SpecialRequestScreenState();
}

class _SpecialRequestScreenState extends State<SpecialRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  int _quantity = 1;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    try {
      await context.read<OrderController>().createSpecialRequest(
        productName: _nameController.text.trim(),
        quantity: _quantity,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.specialSuccess)));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.retry)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          backgroundColor: ClientColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: ClientColors.text,
          title: Text(l10n.specialRequestTitle),
        ),
        body: ClientGlassBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClientCard(
                    borderRadius: 22,
                    child: Row(
                      children: [
                        ClientIconBadge(
                          icon: Icons.info_outline_rounded,
                          color: ClientColors.primary,
                          size: 40,
                          iconSize: 20,
                          borderRadius: 12,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.specialRequestSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ClientColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClientSectionTitle(
                    title: l10n.productNameLabel,
                    icon: Icons.medication_outlined,
                    iconColor: ClientColors.primary,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: l10n.productNameHint,
                      prefixIcon: const Icon(Icons.medication_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? l10n.specialEmptyName
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ClientSectionTitle(
                    title: l10n.specialQuantityLabel,
                    icon: Icons.exposure_plus_1_rounded,
                    iconColor: ClientColors.primary,
                  ),
                  const SizedBox(height: 10),
                  ClientCard(
                    borderRadius: 22,
                    child: Row(
                      children: [
                        IconButton.filled(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$_quantity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClientSectionTitle(
                    title: l10n.specialNotesLabel,
                    icon: Icons.notes_rounded,
                    iconColor: ClientColors.primary,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(l10n.specialSubmit),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
