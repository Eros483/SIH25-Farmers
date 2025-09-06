import 'package:flutter/material.dart';

// Primary color palette - Indian agriculture inspired
const Color primaryColor = Color(0xFF2E7D32); // Deep Green (Forest/Agriculture)
const Color primaryLightColor = Color(0xFF4CAF50); // Light Green
const Color primaryDarkColor = Color(0xFF1B5E20); // Dark Green

// Accent colors - Indian flag and traditional colors
const Color accentColor = Color(0xFFFF9800); // Saffron Orange
const Color accentLightColor = Color(0xFFFFC107); // Amber/Golden
const Color accentDarkColor = Color(0xFFF57C00); // Dark Orange

// Background colors - Clean and modern
const Color backgroundColor = Color(0xFFF8FFF8); // Very light green tint
const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
const Color cardColor = Color(0xFFFFFFFF); // Pure white

// Text colors
const Color textPrimaryColor = Color(0xFF212121); // Dark gray
const Color textSecondaryColor = Color(0xFF757575); // Medium gray
const Color textHintColor = Color(0xFF9E9E9E); // Light gray

// Status colors
const Color successColor = Color(0xFF4CAF50); // Green
const Color warningColor = Color(0xFFFFC107); // Amber
const Color errorColor = Color(0xFFF44336); // Red
const Color infoColor = Color(0xFF2196F3); // Blue

// Gradient combinations for modern look
const List<Color> primaryGradient = [
  Color(0xFF2E7D32),
  Color(0xFF4CAF50),
];

const List<Color> accentGradient = [
  Color(0xFFFF9800),
  Color(0xFFFFC107),
];

const List<Color> backgroundGradient = [
  Color(0xFFF8FFF8),
  Color(0xFFE8F5E8),
];

// Indian traditional colors for special occasions
const Color indianSaffron = Color(0xFFFF9933);
const Color indianGreen = Color(0xFF138808);
const Color indianNavy = Color(0xFF000080);

// Crop-specific colors for categorization
const Color riceColor = Color(0xFFD4AF37); // Golden
const Color wheatColor = Color(0xFFDEB887); // Burlywood
const Color cottonColor = Color(0xFFF5F5DC); // Beige
const Color sugarcaneColor = Color(0xFF9ACD32); // Yellow Green
const Color maizeColor = Color(0xFFFFD700); // Gold

// Seasonal colors
const Color summerColor = Color(0xFFFF6B35); // Orange Red
const Color monsoonColor = Color(0xFF4A90E2); // Blue
const Color winterColor = Color(0xFF7B68EE); // Medium Slate Blue
const Color springColor = Color(0xFF32CD32); // Lime Green

// Material Design 3 inspired color scheme
class AppColorScheme {
  // Light theme colors
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: accentColor,
    onSecondary: Colors.black87,
    error: errorColor,
    onError: Colors.white,
    background: backgroundColor,
    onBackground: textPrimaryColor,
    surface: surfaceColor,
    onSurface: textPrimaryColor,
  );

  // Dark theme colors (for future implementation)
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryLightColor,
    onPrimary: Colors.black87,
    secondary: accentLightColor,
    onSecondary: Colors.black87,
    error: Color(0xFFFF5252),
    onError: Colors.white,
    background: Color(0xFF121212),
    onBackground: Colors.white,
    surface: Color(0xFF1E1E1E),
    onSurface: Colors.white,
  );
}

// Utility class for gradient definitions
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLightColor],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, accentLightColor],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundColor, Color(0xFFE8F5E8)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF8FFF8)],
  );

  // Seasonal gradients
  static const LinearGradient summerGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFFA726)],
  );

  static const LinearGradient monsoonGradient = LinearGradient(
    colors: [Color(0xFF4A90E2), Color(0xFF64B5F6)],
  );

  static const LinearGradient winterGradient = LinearGradient(
    colors: [Color(0xFF7B68EE), Color(0xFF9575CD)],
  );

  static const LinearGradient springGradient = LinearGradient(
    colors: [Color(0xFF32CD32), Color(0xFF66BB6A)],
  );
}

// Utility class for shadows
class AppShadows {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.1),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: accentColor.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ];
}

// Border radius constants
class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xlarge = 20.0;

  static BorderRadius smallRadius = BorderRadius.circular(small);
  static BorderRadius mediumRadius = BorderRadius.circular(medium);
  static BorderRadius largeRadius = BorderRadius.circular(large);
  static BorderRadius xlargeRadius = BorderRadius.circular(xlarge);
}

// Animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xslow = Duration(milliseconds: 800);
}
