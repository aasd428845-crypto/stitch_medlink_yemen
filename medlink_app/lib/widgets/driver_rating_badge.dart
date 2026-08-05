import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Compact badge showing a driver's average star rating and review count.
/// Pass [average] and [count] once fetched; shows a loading skeleton while null.
///
/// Usage:
///   DriverRatingBadge(average: 4.6, count: 12)
///   DriverRatingBadge(average: null, count: 0)  // loading state
class DriverRatingBadge extends StatelessWidget {
  const DriverRatingBadge({
    super.key,
    required this.average,
    required this.count,
    this.noRatingsLabel = 'لا توجد تقييمات',
  });

  final double? average;
  final int count;
  final String noRatingsLabel;

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (average == null && count == 0) {
      return Container(
        height: 22,
        width: 70,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      );
    }

    // No ratings yet
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          noRatingsLabel,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    final avgStr = average!.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: 2),
          Text(
            '$avgStr · $count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
