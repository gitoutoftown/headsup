/// Design system for HeadsUp app
/// Minimalist aesthetic with clean typography and subtle colors
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette
class AppColors {
  // Light mode
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color characterLight = Color(0xFF000000);
  
  // Dark mode
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color characterDark = Color(0xFFFFFFFF);
  
  // Accent colors
  static const Color primary = Color(0xFF4A90E2);
  static const Color accent = Color(0xFF4A90E2);
  static const Color alert = Color(0xFFFF9500);
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  
  // 5-Tier Posture state colors
  static const Color postureExcellent = Color(0xFF00C853);  // Vibrant green
  static const Color postureGood = Color(0xFF007AFF);       // Blue
  static const Color postureOkay = Color(0xFFFFD60A);       // Yellow
  static const Color postureBad = Color(0xFFFF9500);        // Orange
  static const Color posturePoor = Color(0xFFFF3B30);       // Red
  
  // Legacy aliases
  static const Color postureFair = postureOkay;
}

/// Typography styles
class AppTypography {
  static const String fontFamily = '.SF Pro Text'; // System font on iOS
  
  // Hero numbers (posture score)
  static const TextStyle heroNumber = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
  );
  
  // Large score display
  static const TextStyle scoreDisplay = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.1,
  );
  
  // Page titles
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
  
  // Section headers
  static const TextStyle headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  
  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.4,
  );
  
  // Secondary/caption text
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.3,
  );
  
  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  
  // Timer display
  static const TextStyle timer = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: 2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Spacing constants (8px base unit)
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  // Standard padding
  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );
}

/// Border radius constants
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 100;
  
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(24),
  );
}

/// Shadows
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
}

/// Animation durations
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration characterTransition = Duration(milliseconds: 1000);
  
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
}

/// Theme data
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surfaceLight,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
    ),
    textTheme: _buildTextTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        textStyle: AppTypography.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        minimumSize: const Size(double.infinity, 56),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        side: BorderSide(color: AppColors.textPrimaryLight.withValues(alpha: 0.2)),
        textStyle: AppTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondaryLight,
        textStyle: AppTypography.body,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheetRadius,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surfaceDark,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
    ),
    textTheme: _buildTextTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        textStyle: AppTypography.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        minimumSize: const Size(double.infinity, 56),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        side: BorderSide(color: AppColors.textPrimaryDark.withValues(alpha: 0.2)),
        textStyle: AppTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondaryDark,
        textStyle: AppTypography.body,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sheetRadius,
      ),
    ),
  );
  
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    final baseTheme = TextTheme(
      displayLarge: AppTypography.heroNumber.copyWith(color: primary),
      displayMedium: AppTypography.scoreDisplay.copyWith(color: primary),
      headlineLarge: AppTypography.title.copyWith(color: primary),
      headlineMedium: AppTypography.headline.copyWith(color: primary),
      bodyLarge: AppTypography.body.copyWith(color: primary),
      bodyMedium: AppTypography.body.copyWith(color: secondary),
      labelLarge: AppTypography.button.copyWith(color: primary),
      bodySmall: AppTypography.caption.copyWith(color: secondary),
    );
    
    return GoogleFonts.interTextTheme(baseTheme);
  }
}
