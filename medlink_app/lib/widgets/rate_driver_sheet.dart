import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/order_service.dart';
import '../utils/theme.dart';

/// Bottom sheet that lets a client rate a delivered order's driver.
///
/// [orderId] and [driverId] are required.
/// [onRated] is called after the rating is successfully submitted,
/// passing the submitted rating int so the parent can update its UI.
class RateDriverSheet extends StatefulWidget {
  const RateDriverSheet({
    super.key,
    required this.orderId,
    required this.driverId,
    required this.onRated,
  });

  final String orderId;
  final String driverId;
  final void Function(int rating, String? comment) onRated;

  @override
  State<RateDriverSheet> createState() => _RateDriverSheetState();
}

class _RateDriverSheetState extends State<RateDriverSheet> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final service = context.read<OrderService>();
      await service.submitDriverRating(
        orderId: widget.orderId,
        driverId: widget.driverId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (!mounted) return;
      // Notify parent before closing
      widget.onRated(
        _selectedRating,
        _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.rateDriverSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      // Detect unique-constraint violation (already rated)
      final msg = e.toString().toLowerCase();
      setState(() {
        _error = msg.contains('unique') || msg.contains('duplicate')
            ? l10n.rateDriverAlreadyRated
            : e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            l10n.rateDriverTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.rateDriverPrompt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    _selectedRating >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 42,
                    color: _selectedRating >= star
                        ? AppColors.warning
                        : AppColors.outlineVariant,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.rateDriverCommentHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Error
          if (_error != null) ...[
            Text(
              _error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Submit button
          FilledButton(
            onPressed:
                (_selectedRating == 0 || _isSubmitting) ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.rateDriverSubmit),
          ),
        ],
      ),
    );
  }
}
