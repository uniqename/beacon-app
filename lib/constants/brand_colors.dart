import 'package:flutter/material.dart';

/// Official Beacon of New Beginnings Brand Colors
///
/// Based on the official Beacon Brand Guidance document.
/// These colors represent the organization's identity and should be used
/// consistently throughout the application.
class BeaconColors {
  // Primary Brand Color
  /// Vibrant Orange (#F0562D)
  ///
  /// Radiates warmth, energy, and hope, symbolizing courage, transformation,
  /// and the spark of new beginnings.
  ///
  /// Use for:
  /// - Primary actions and buttons
  /// - Live indicators and active states
  /// - Emphasis and highlights
  /// - Brand logo
  static const vibrantOrange = Color(0xFFF0562D);

  // Secondary Colors
  /// Soft Sage Green (#C6DEAD)
  ///
  /// Radiates warmth, energy, and hope, symbolizing courage, transformation,
  /// and the spark of new beginnings.
  ///
  /// Use for:
  /// - Calm, supportive elements
  /// - Group cards and accents
  /// - Success states
  /// - Growth-related features
  static const softSageGreen = Color(0xFFC6DEAD);

  /// Deep Charcoal (#221E1F)
  ///
  /// Grounded and authoritative, this color conveys strength, stability,
  /// and the seriousness of the brand's mission.
  ///
  /// Use for:
  /// - Primary text
  /// - Headers and titles
  /// - Icons
  /// - Dark backgrounds
  static const deepCharcoal = Color(0xFF221E1F);

  /// Warm Off-White (#EAEADA)
  ///
  /// Brings light, openness, and purity, balancing the palette with clarity
  /// and calm reassurance.
  ///
  /// Use for:
  /// - Backgrounds
  /// - Cards and containers
  /// - Light text on dark backgrounds
  /// - Dividers and borders (subtle)
  static const warmOffWhite = Color(0xFFEAEADA);

  // Utility Colors (derived from brand colors)

  /// Light tint of Vibrant Orange for backgrounds
  static const vibrantOrangeTint = Color(0xFFFFF0EC);

  /// Light tint of Soft Sage Green for backgrounds
  static const softSageGreenTint = Color(0xFFF2F5EC);

  /// Semi-transparent Vibrant Orange for overlays
  static Color vibrantOrangeOverlay(double opacity) =>
    vibrantOrange.withValues(alpha: opacity);

  /// Semi-transparent Soft Sage Green for overlays
  static Color softSageGreenOverlay(double opacity) =>
    softSageGreen.withValues(alpha: opacity);

  // Common Color Combinations

  /// Primary gradient (Vibrant Orange)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [vibrantOrange, Color(0xFFE04925)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Success gradient (Soft Sage Green)
  static const LinearGradient successGradient = LinearGradient(
    colors: [softSageGreen, Color(0xFFB5D29D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [warmOffWhite, Color(0xFFF5F5ED)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Text Color Utilities

  /// Primary text color (Deep Charcoal)
  static const textPrimary = deepCharcoal;

  /// Secondary text color (softer Deep Charcoal)
  static const textSecondary = Color(0xFF4A4748);

  /// Text color for light backgrounds
  static const textOnLight = deepCharcoal;

  /// Text color for dark backgrounds
  static const textOnDark = warmOffWhite;

  /// Text color for orange backgrounds
  static const textOnOrange = Colors.white;

  // Shadow Colors

  /// Soft shadow for cards
  static final cardShadow = BoxShadow(
    color: deepCharcoal.withValues(alpha: 0.08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  /// Elevated shadow for prominent cards
  static final elevatedShadow = BoxShadow(
    color: vibrantOrange.withValues(alpha: 0.15),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  // Semantic Colors (using brand palette)

  /// Success color (Soft Sage Green)
  static const success = softSageGreen;

  /// Warning color (Vibrant Orange)
  static const warning = vibrantOrange;

  /// Error color (slightly darker Vibrant Orange)
  static const error = Color(0xFFD9381E);

  /// Info color (muted teal derived from Sage Green)
  static const info = Color(0xFF7BA591);

  // Private constructor to prevent instantiation
  BeaconColors._();
}

/// Extension on ThemeData to easily apply Beacon brand colors
extension BeaconTheme on ThemeData {
  /// Creates a ThemeData with Beacon brand colors
  static ThemeData light() {
    return ThemeData(
      primaryColor: BeaconColors.vibrantOrange,
      scaffoldBackgroundColor: BeaconColors.warmOffWhite,
      colorScheme: const ColorScheme.light(
        primary: BeaconColors.vibrantOrange,
        secondary: BeaconColors.softSageGreen,
        surface: BeaconColors.warmOffWhite,
        error: BeaconColors.error,
        onPrimary: Colors.white,
        onSecondary: BeaconColors.deepCharcoal,
        onSurface: BeaconColors.deepCharcoal,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: BeaconColors.deepCharcoal),
        displayMedium: TextStyle(color: BeaconColors.deepCharcoal),
        displaySmall: TextStyle(color: BeaconColors.deepCharcoal),
        headlineLarge: TextStyle(color: BeaconColors.deepCharcoal),
        headlineMedium: TextStyle(color: BeaconColors.deepCharcoal),
        headlineSmall: TextStyle(color: BeaconColors.deepCharcoal),
        titleLarge: TextStyle(color: BeaconColors.deepCharcoal),
        titleMedium: TextStyle(color: BeaconColors.deepCharcoal),
        titleSmall: TextStyle(color: BeaconColors.deepCharcoal),
        bodyLarge: TextStyle(color: BeaconColors.textPrimary),
        bodyMedium: TextStyle(color: BeaconColors.textPrimary),
        bodySmall: TextStyle(color: BeaconColors.textSecondary),
        labelLarge: TextStyle(color: BeaconColors.deepCharcoal),
        labelMedium: TextStyle(color: BeaconColors.deepCharcoal),
        labelSmall: TextStyle(color: BeaconColors.textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BeaconColors.vibrantOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BeaconColors.vibrantOrange,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: BeaconColors.deepCharcoal.withValues(alpha: 0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BeaconColors.vibrantOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BeaconColors.deepCharcoal,
          side: const BorderSide(color: BeaconColors.deepCharcoal),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BeaconColors.vibrantOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BeaconColors.deepCharcoal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: BeaconColors.deepCharcoal.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BeaconColors.vibrantOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BeaconColors.error),
        ),
        labelStyle: const TextStyle(color: BeaconColors.textSecondary),
        hintStyle: TextStyle(color: BeaconColors.textSecondary.withValues(alpha: 0.6)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BeaconColors.softSageGreen;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BeaconColors.vibrantOrange;
          }
          return BeaconColors.textSecondary;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BeaconColors.vibrantOrange;
          }
          return BeaconColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BeaconColors.vibrantOrange.withValues(alpha: 0.5);
          }
          return BeaconColors.textSecondary.withValues(alpha: 0.3);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BeaconColors.vibrantOrange,
        linearTrackColor: BeaconColors.warmOffWhite,
      ),
      dividerTheme: DividerThemeData(
        color: BeaconColors.deepCharcoal.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
