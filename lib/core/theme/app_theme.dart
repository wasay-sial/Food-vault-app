import 'package:flutter/material.dart';

class AppTheme {
  // Color palette from Olive Garden theme (vibrant version)
  static const Color primaryColor = Color(0xFF6B7B5F); // Vibrant Sage
  static const Color secondaryColor = Color(0xFF9E9A85); // Vibrant Sand
  static const Color accentColor = Color(0xFF5A5A4A); // Rich Bark
  static const Color backgroundColor = Color(0xFFFFF0DB); // Light Peach
  static const Color surfaceColor = Color(0xFFF0E9DD); // Warm Sand light
  static const Color cardColor = Color(0xFF87A96B); // Vibrant Sage
  static const Color textColor = Color(0xFF363630); // Deep Olivewood
  static const Color buttonBackgroundColor = Color(0xFF4E5D4A); // Darker Olive
  static const Color accentIconColor = Color(0xFFFFC107); // Vibrant Gold for icons
  static const Color errorColor = Color(0xFFA65D2E); // Rich Saddle Brown

  // Gradients with more vibrant transitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6B7B5F), Color(0xFF8B9584)], // Vibrant Sage to Olive
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFFAF7EE),
      Color(0xFFF0E9DD),
    ], // Bright Parchment to Warm Sand
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF87A96B), Color(0xFFA3C585)], // Vibrant Sage to Light Vibrant Sage
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF6B7B5F), Color(0xFF5A5A4A)], // Vibrant Sage to Rich Bark
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Glass effect
  static BoxDecoration glassDecoration = BoxDecoration(
    color: surfaceColor.withOpacity(0.7),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: primaryColor.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.1),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );

  // Modern card decoration
  static BoxDecoration modernCardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryColor.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Navigation bar decoration
  static BoxDecoration navigationBarDecoration = BoxDecoration(
    color: surfaceColor.withOpacity(0.95),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    border: Border.all(color: primaryColor.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, -2),
      ),
    ],
  );

  // Text field decoration
  static InputDecoration textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppTheme.textColor.withOpacity(0.7),
        fontSize: 14,
        fontFamily: 'PlayfairDisplay',
        fontWeight: FontWeight.w400,
      ),
      hintStyle: TextStyle(
        color: AppTheme.textColor.withOpacity(0.5),
        fontSize: 14,
        fontFamily: 'PlayfairDisplay',
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: surfaceColor.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Button styles
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    backgroundColor: AppTheme.buttonBackgroundColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.pressed)) {
        return Colors.white.withOpacity(0.1);
      }
      return null;
    }),
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    foregroundColor: textColor,
    side: BorderSide(color: primaryColor.withOpacity(0.2)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.pressed)) {
        return primaryColor.withOpacity(0.05);
      }
      return null;
    }),
  );

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textColor,
    fontFamily: 'PlayfairDisplay',
    letterSpacing: 0.5,
  );

  static TextStyle subheadingStyle = TextStyle(
    fontSize: 14,
    color: textColor.withOpacity(0.7),
    fontFamily: 'PlayfairDisplay',
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: 'PlayfairDisplay',
    letterSpacing: 0.5,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    fontFamily: 'PlayfairDisplay',
    letterSpacing: 0.5,
  );

  static TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 12,
    color: Colors.white.withOpacity(0.9),
    fontFamily: 'PlayfairDisplay',
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );
}
