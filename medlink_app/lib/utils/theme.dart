import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central visual tokens for the MedLink experience.
///
/// The product is intentionally dark-first: the navy foundation keeps long
/// operational sessions comfortable while cyan and teal accents make the
/// next action and status easy to scan.
class AppColors {
  AppColors._();

  static const midnightNavy = Color(0xFF071226);
  static const deepNavy = Color(0xFF0C1D38);
  static const deepBlue = Color(0xFF10294A);
  static const primary = Color(0xFF36C9F4);
  static const primaryContainer = Color(0xFF124D73);
  static const onPrimary = midnightNavy;
  static const onPrimaryContainer = Color(0xFFBCEFFF);

  static const secondary = Color(0xFF8FA9C8);
  static const secondaryContainer = Color(0xFF1A385B);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFFC5D9F3);

  static const tertiary = Color(0xFF71E0CA);
  static const tertiaryContainer = Color(0xFF124D4E);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFFB7F5E6);

  static const error = Color(0xFFFF6F78);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFF5C1D2A);
  static const onErrorContainer = Color(0xFFFFD9DC);

  static const background = midnightNavy;
  static const onBackground = Color(0xFFF1F7FF);
  static const surface = deepNavy;
  static const onSurface = Color(0xFFF1F7FF);
  static const onSurfaceVariant = Color(0xFFA8BAD2);
  static const surfaceVariant = deepBlue;
  static const surfaceContainerLowest = Color(0xFF0A192F);
  static const surfaceContainerLow = Color(0xFF0D203C);
  static const surfaceContainer = Color(0xFF112847);
  static const surfaceContainerHigh = Color(0xFF173253);
  static const surfaceContainerHighest = Color(0xFF1D3B5D);

  static const outline = Color(0xFF607D9F);
  static const outlineVariant = Color(0xFF294766);
  static const inverseSurface = Color(0xFFE7F4FF);
  static const inverseOnSurface = Color(0xFF142033);
  static const inversePrimary = Color(0xFF00617B);

  static const success = Color(0xFF71E0CA);
  static const successContainer = Color(0xFF123F42);
  static const warning = Color(0xFFFFC857);
  static const warningContainer = Color(0xFF4A391B);
  static const violet = Color(0xFFA79BFF);
  static const violetContainer = Color(0xFF302C61);
  static const coral = Color(0xFFFF7E88);
}

/// Light design tokens for the branch-manager screens, taken verbatim from
/// the approved design (Material 3 Light palette + status colors).
///
/// Rule: screens MUST reference these tokens — never define `Color(0x…)`
/// inline. Shared AppColors above stays dark-first for client/driver roles.
class BranchColors {
  BranchColors._();

  // Material 3 Light palette (design's tailwind tokens)
  static const background = Color(0xFFFAF8FF);
  static const surface = Color(0xFFFAF8FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F3FE);
  static const surfaceContainer = Color(0xFFEDEDF9);
  static const surfaceContainerHigh = Color(0xFFE7E7F3);
  static const surfaceContainerHighest = Color(0xFFE1E2ED);
  static const surfaceVariant = Color(0xFFE1E2ED);
  static const onSurface = Color(0xFF191B23);
  static const onSurfaceVariant = Color(0xFF434655);

  static const primary = Color(0xFF004AC6);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimaryContainer = Color(0xFFEEEFFF);

  static const secondary = Color(0xFF505F76);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFD0E1FB);
  static const onSecondaryContainer = Color(0xFF54647A);

  static const tertiary = Color(0xFF943700);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryFixed = Color(0xFFFFDBCD);
  static const onTertiaryFixedVariant = Color(0xFF7D2D00);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const outline = Color(0xFF737686);
  static const outlineVariant = Color(0xFFC3C6D7);

  // Status colors used by chips/badges (green/amber/red/orange families)
  static const success = Color(0xFF16A34A);
  static const successContainer = Color(0xFFDCFCE7);
  static const onSuccessContainer = Color(0xFF166534);

  static const warning = Color(0xFFD97706);
  static const warningContainer = Color(0xFFFEF3C7);
  static const onWarningContainer = Color(0xFF92400E);

  static const danger = Color(0xFFDC2626);
  static const dangerContainer = Color(0xFFFEE2E2);
  static const onDangerContainer = Color(0xFF991B1B);

  static const overdueContainer = Color(0xFFFFEDD5);
  static const onOverdueContainer = Color(0xFF9A3412);

  // Surfaces & gradients from the design
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate800 = Color(0xFF1E293B);

  static const heroGradient = <Color>[
    Color(0xFF1E3A8A),
    Color(0xFF2563EB),
    Color(0xFF3B82F6),
  ];
  static const tabActiveGradient = <Color>[Color(0xFF2563EB), Color(0xFF1E40AF)];

  // ---- Modern Glassmorphism tokens (soft pastel, branch manager) ----
  static const glassBackgroundStart = Color(0xFFF2F4FF);
  static const glassBackgroundEnd   = Color(0xFFE8EEFF);
  static const glassSurface         = Color(0xFFFFFFFF);
  static const glassSurfaceOpacity  = 0.75;
  static const glassBorder          = Color(0x33FFFFFF);

  // Hero header: violet → pink → sky
  static const glassHeroGradient = <Color>[
    Color(0xFF7B6EF6),
    Color(0xFFB06AB3),
    Color(0xFF63B3ED),
  ];

  // Warm central FAB gradient
  static const glassWarmGradient = <Color>[
    Color(0xFFFF9A8B),
    Color(0xFFFF6A88),
    Color(0xFFFF99AC),
  ];

  // Accent gradients for Quick Action cards
  static const pastelBluGradient    = <Color>[Color(0xFF4361EE), Color(0xFF60A5FA)];
  static const pastelGreenGradient  = <Color>[Color(0xFF10B981), Color(0xFF6EE7B7)];
  static const pastelAmberGradient  = <Color>[Color(0xFFF59E0B), Color(0xFFFCD34D)];
  static const pastelVioletGradient = <Color>[Color(0xFF8B5CF6), Color(0xFFC4B5FD)];

  // Primary blue gradient (charts / progress)
  static const glassPrimaryGradient = <Color>[
    Color(0xFF4361EE),
    Color(0xFF60A5FA),
  ];

  // Metric tile accent gradients
  static const metricOrangeGradient = <Color>[Color(0xFFF59E0B), Color(0xFFFB923C)];
  static const metricBlueGradient   = <Color>[Color(0xFF4361EE), Color(0xFF818CF8)];
  static const metricGreenGradient  = <Color>[Color(0xFF10B981), Color(0xFF34D399)];
  static const metricPurpleGradient = <Color>[Color(0xFF8B5CF6), Color(0xFFA78BFA)];

  // Decorative background orbs
  static const orbMint   = Color(0xFFBFF2E6);
  static const orbSky    = Color(0xFFB9D8FF);
  static const orbViolet = Color(0xFFE0D4FF);
  static const orbPink   = Color(0xFFFFD9E8);
  static const orbPeach  = Color(0xFFFFE3C7);
}

class AppRadius {
  AppRadius._();
  static const sm = 4.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const full = 999.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final textTheme = GoogleFonts.beVietnamProTextTheme().copyWith(
      headlineLarge: GoogleFonts.beVietnamPro(
        fontSize: 29,
        fontWeight: FontWeight.w700,
        height: 38 / 30,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.beVietnamPro(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: AppColors.onSurface,
      ),
      headlineSmall: GoogleFonts.beVietnamPro(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.onSurface,
      ),
      bodyLarge: GoogleFonts.beVietnamPro(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.02 * 14,
        height: 20 / 14,
      ),
      labelMedium: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      ),
    );

    final colorScheme = const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      brightness: Brightness.dark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppSpacing.md,
        titleTextStyle: textTheme.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          side: const BorderSide(color: AppColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 0.7,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.deepNavy.withValues(alpha: 0.97),
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  /// Kept as an alias so older screens that still reference `light` can be
  /// migrated incrementally without creating a second visual language.
  static ThemeData get light => dark;

  /// Light theme for the branch-manager area, matching the approved design.
  /// Applied by wrapping the branch shell body in `Theme(data: …)`; every
  /// branch screen + its dialogs/sheets inherit it.
  static ThemeData get branchManagerLight {
    final textTheme = GoogleFonts.tajawalTextTheme().copyWith(
      headlineLarge: GoogleFonts.tajawal(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 38 / 30,
        color: BranchColors.onSurface,
      ),
      headlineMedium: GoogleFonts.tajawal(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 34 / 26,
        color: BranchColors.onSurface,
      ),
      headlineSmall: GoogleFonts.tajawal(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 28 / 21,
        color: BranchColors.onSurface,
      ),
      titleMedium: GoogleFonts.tajawal(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 24 / 17,
        color: BranchColors.onSurface,
      ),
      titleSmall: GoogleFonts.tajawal(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 20 / 15,
        color: BranchColors.onSurface,
      ),
      bodyLarge: GoogleFonts.tajawal(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 28 / 18,
        color: BranchColors.onSurface,
      ),
      bodyMedium: GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: BranchColors.onSurface,
      ),
      bodySmall: GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: BranchColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.tajawal(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.01 * 15,
        height: 20 / 15,
        color: BranchColors.onSurface,
      ),
      labelMedium: GoogleFonts.tajawal(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        color: BranchColors.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.tajawal(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        color: BranchColors.onSurfaceVariant,
      ),
    );

    final colorScheme = const ColorScheme.light(
      primary: BranchColors.primary,
      onPrimary: BranchColors.onPrimary,
      primaryContainer: BranchColors.primaryContainer,
      onPrimaryContainer: BranchColors.onPrimaryContainer,
      secondary: BranchColors.secondary,
      onSecondary: BranchColors.onSecondary,
      secondaryContainer: BranchColors.secondaryContainer,
      onSecondaryContainer: BranchColors.onSecondaryContainer,
      tertiary: BranchColors.tertiary,
      onTertiary: BranchColors.onTertiary,
      tertiaryContainer: BranchColors.tertiary,
      onTertiaryContainer: BranchColors.onTertiaryFixedVariant,
      error: BranchColors.error,
      onError: BranchColors.onError,
      errorContainer: BranchColors.errorContainer,
      onErrorContainer: BranchColors.onErrorContainer,
      surface: BranchColors.surface,
      onSurface: BranchColors.onSurface,
      onSurfaceVariant: BranchColors.onSurfaceVariant,
      surfaceContainerLowest: BranchColors.surfaceContainerLowest,
      surfaceContainerLow: BranchColors.surfaceContainerLow,
      surfaceContainer: BranchColors.surfaceContainer,
      surfaceContainerHigh: BranchColors.surfaceContainerHigh,
      surfaceContainerHighest: BranchColors.surfaceContainerHighest,
      outline: BranchColors.outline,
      outlineVariant: BranchColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      brightness: Brightness.light,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: BranchColors.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.md,
        titleTextStyle: textTheme.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BranchColors.glassSurface.withValues(alpha: .7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: BranchColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: BranchColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: BranchColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: BranchColors.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: BranchColors.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BranchColors.primaryContainer,
          foregroundColor: BranchColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BranchColors.primaryContainer,
          foregroundColor: BranchColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BranchColors.primary,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          side: const BorderSide(color: BranchColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BranchColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: BranchColors.glassSurface.withValues(alpha: .7),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BranchColors.outlineVariant,
        thickness: 0.7,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BranchColors.slate800,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: BranchColors.onPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}
