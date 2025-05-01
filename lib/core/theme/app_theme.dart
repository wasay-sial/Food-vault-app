import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color primaryColor = Color(0xFF3B4BF9); // Primary Blue
  static const Color secondaryColor = Color(0xFF6B4BF9); // Purple Blue
  static const Color accentColor = Color(0xFF8F6BFF); // Light Purple
  static const Color backgroundColor = Color(
    0xFF0A0B1E,
  ); // Dark Blue Background
  static const Color surfaceColor = Color(
    0xFF1A1B2E,
  ); // Slightly lighter surface
  static const Color cardColor = Color(0xFF252642); // Card background
  static const Color textColor = Colors.white;
  static const Color errorColor = Color(0xFFFF3B3B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B4BF9), Color(0xFF6B4BF9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0B1E), Color(0xFF1A1B2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF252642), Color(0xFF1E1F38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF3B4BF9), Color(0xFF6B4BF9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Glass effect
  static BoxDecoration glassDecoration = BoxDecoration(
    color: surfaceColor.withOpacity(0.7),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
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
    border: Border.all(color: Colors.white.withOpacity(0.1)),
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
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
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
        color: Colors.white.withOpacity(0.7),
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
      filled: true,
      fillColor: surfaceColor.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    foregroundColor: Colors.white,
    side: BorderSide(color: Colors.white.withOpacity(0.2)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.pressed)) {
        return Colors.white.withOpacity(0.05);
      }
      return null;
    }),
  );

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
  );

  static TextStyle subheadingStyle = TextStyle(
    fontSize: 14,
    color: Colors.white.withOpacity(0.7),
    fontFamily: 'Roboto',
    letterSpacing: 0.25,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
  );

  static TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 12,
    color: Colors.white.withOpacity(0.7),
    fontFamily: 'Roboto',
    letterSpacing: 0.25,
  );
}
