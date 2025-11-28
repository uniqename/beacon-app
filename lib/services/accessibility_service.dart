import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility service for font sizing and other accessibility features
/// Helps low vision and elderly users adjust text size for better readability
class AccessibilityService extends ChangeNotifier {
  static const String _fontSizeKey = 'accessibility_font_size';
  static const String _highContrastKey = 'accessibility_high_contrast';

  double _fontSizeMultiplier = 1.0;
  bool _highContrastMode = false;
  bool _isInitialized = false;

  // Font size multipliers for different settings
  static const double fontSizeSmall = 0.85;
  static const double fontSizeNormal = 1.0;
  static const double fontSizeLarge = 1.15;
  static const double fontSizeExtraLarge = 1.3;
  static const double fontSizeHuge = 1.5;

  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get highContrastMode => _highContrastMode;
  bool get isInitialized => _isInitialized;

  /// Get font size name for UI display
  String get fontSizeName {
    if (_fontSizeMultiplier <= fontSizeSmall) return 'Small';
    if (_fontSizeMultiplier <= fontSizeNormal) return 'Normal';
    if (_fontSizeMultiplier <= fontSizeLarge) return 'Large';
    if (_fontSizeMultiplier <= fontSizeExtraLarge) return 'Extra Large';
    return 'Huge';
  }

  /// Initialize and load saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSizeMultiplier = prefs.getDouble(_fontSizeKey) ?? fontSizeNormal;
      _highContrastMode = prefs.getBool(_highContrastKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing accessibility service: $e');
      _isInitialized = true;
    }
  }

  /// Set font size multiplier
  Future<void> setFontSize(double multiplier) async {
    if (multiplier < 0.5 || multiplier > 2.0) {
      throw ArgumentError('Font size multiplier must be between 0.5 and 2.0');
    }

    _fontSizeMultiplier = multiplier;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, multiplier);
    } catch (e) {
      print('Error saving font size: $e');
    }
  }

  /// Set high contrast mode
  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_highContrastKey, enabled);
    } catch (e) {
      print('Error saving high contrast mode: $e');
    }
  }

  /// Reset all accessibility settings to default
  Future<void> resetToDefaults() async {
    _fontSizeMultiplier = fontSizeNormal;
    _highContrastMode = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fontSizeKey);
      await prefs.remove(_highContrastKey);
    } catch (e) {
      print('Error resetting accessibility settings: $e');
    }
  }

  /// Get scaled text style based on current settings
  TextStyle scaleTextStyle(TextStyle? baseStyle) {
    if (baseStyle == null) {
      return TextStyle(fontSize: 14 * _fontSizeMultiplier);
    }

    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * _fontSizeMultiplier,
    );
  }

  /// Get theme data with accessibility adjustments
  ThemeData getAccessibleTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      textTheme: _scaleTextTheme(baseTheme.textTheme),
      primaryTextTheme: _scaleTextTheme(baseTheme.primaryTextTheme),
      visualDensity: _fontSizeMultiplier > fontSizeLarge
          ? VisualDensity.comfortable
          : VisualDensity.standard,
    );
  }

  TextTheme _scaleTextTheme(TextTheme textTheme) {
    return TextTheme(
      displayLarge: _scaleStyle(textTheme.displayLarge),
      displayMedium: _scaleStyle(textTheme.displayMedium),
      displaySmall: _scaleStyle(textTheme.displaySmall),
      headlineLarge: _scaleStyle(textTheme.headlineLarge),
      headlineMedium: _scaleStyle(textTheme.headlineMedium),
      headlineSmall: _scaleStyle(textTheme.headlineSmall),
      titleLarge: _scaleStyle(textTheme.titleLarge),
      titleMedium: _scaleStyle(textTheme.titleMedium),
      titleSmall: _scaleStyle(textTheme.titleSmall),
      bodyLarge: _scaleStyle(textTheme.bodyLarge),
      bodyMedium: _scaleStyle(textTheme.bodyMedium),
      bodySmall: _scaleStyle(textTheme.bodySmall),
      labelLarge: _scaleStyle(textTheme.labelLarge),
      labelMedium: _scaleStyle(textTheme.labelMedium),
      labelSmall: _scaleStyle(textTheme.labelSmall),
    );
  }

  TextStyle? _scaleStyle(TextStyle? style) {
    if (style == null) return null;
    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * _fontSizeMultiplier,
    );
  }
}
