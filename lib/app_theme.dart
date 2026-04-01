import 'package:flutter/material.dart';

// ── Brand Colors ──────────────────────────────────────────────────────────────
class AppColors {
  // Primary
  static const primary = Color(0xFF1A237E); // Deep Indigo
  static const primaryLight = Color(0xFF3949AB); // Lighter Indigo
  static const primaryDark = Color(0xFF0D1347); // Darker Indigo

  // Accent
  static const accent = Color(0xFF00BFA5); // Teal
  static const accentLight = Color(0xFF64FFDA); // Light Teal
  static const accentDark = Color(0xFF00897B); // Dark Teal

  // Semantic
  static const success = Color(0xFF2E7D32); // Deep Green
  static const successLight = Color(0xFFE8F5E9); // Light Green bg
  static const error = Color(0xFFC62828); // Deep Red
  static const errorLight = Color(0xFFFFEBEE); // Light Red bg
  static const warning = Color(0xFFF57F17); // Amber
  static const warningLight = Color(0xFFFFF8E1); // Light Amber bg

  // Neutrals
  static const background = Color(0xFFF5F5F5); // Light Grey
  static const surface = Color(0xFFFFFFFF); // White
  static const surfaceVariant = Color(0xFFF0F0F0); // Off White
  static const divider = Color(0xFFE0E0E0); // Divider Grey

  // Text
  static const textPrimary = Color(0xFF212121); // Near Black
  static const textSecondary = Color(0xFF757575); // Grey
  static const textHint = Color(0xFFBDBDBD); // Light Grey
  static const textOnPrimary = Color(0xFFFFFFFF); // White on dark bg
  static const textOnAccent = Color(0xFFFFFFFF); // White on teal

  // PIN dots
  static const pinFilled = Color(0xFF1A237E); // Primary
  static const pinEmpty = Color(0xFFE0E0E0); // Grey
}

// ── Text Styles ───────────────────────────────────────────────────────────────
class AppTextStyles {
  static const _base = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.textPrimary,
  );

  // Display
  static final displayLarge = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static final displayMedium = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  // Headings
  static final headingLarge = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static final headingMedium = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final headingSmall = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // Body
  static final bodyLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static final bodyMedium = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static final bodySmall = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Labels
  static final labelLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static final labelMedium = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static final labelSmall = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  // Amount — large currency display
  static final amount = _base.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: AppColors.primary,
  );

  // UPI ID
  static final upiId = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

// ── Spacing ───────────────────────────────────────────────────────────────────
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// ── Border Radius ─────────────────────────────────────────────────────────────
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const full = 100.0;
}

// ── Shadows ───────────────────────────────────────────────────────────────────
class AppShadows {
  static final card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final elevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final subtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

// ── Reusable Decorations ──────────────────────────────────────────────────────
class AppDecorations {
  static BoxDecoration card({
    Color? color,
    double radius = AppRadius.lg,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      );

  static BoxDecoration primaryGradient = BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(AppRadius.lg),
  );

  static BoxDecoration inputField = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: AppColors.divider,
      width: 1.5,
    ),
  );

  static BoxDecoration inputFieldFocused = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: AppColors.primary,
      width: 2.0,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// ── Main App Theme ────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),

        // Cards
        cardTheme: CardTheme(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),

        // Filled buttons
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),

        // Outlined buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
        ),

        // Text buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.labelMedium,
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
      );
}
