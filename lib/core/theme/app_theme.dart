import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color primaryColor = Color(0xFF2E7D32); // Dark Green
  static const Color secondaryColor = Color(0xFF4CAF50); // Medium Green
  static const Color accentColor = Color(0xFF81C784); // Light Green
  static const Color backgroundColor = Color(0xFFF1F8E9); // Very Light Green
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1B5E20); // Dark Green for text
  static const Color errorColor = Color(0xFFD32F2F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Glass effect
  static BoxDecoration glassDecoration = BoxDecoration(
    color: surfaceColor.withOpacity(0.95),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(0, -4),
      ),
    ],
  );

  // Text field decoration
  static InputDecoration textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF4CAF50),
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
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
    padding: const EdgeInsets.symmetric(vertical: 12),
    backgroundColor: const Color(0xFF2E7D32),
    foregroundColor: Colors.white,
    elevation: 3,
    shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    foregroundColor: const Color(0xFF2E7D32),
    side: const BorderSide(color: Color(0xFF2E7D32)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(0, -4),
      ),
    ],
  );

  // Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1B5E20),
    fontFamily: 'Roboto',
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF4CAF50),
    fontFamily: 'Roboto',
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );
}
