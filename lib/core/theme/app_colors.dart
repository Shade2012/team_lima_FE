import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFAF06FF);
  static const Color primaryDark = Color(0xFF8A00CC);
  static const Color primaryLight = Color(0xFFD580FF);

  static const Color pink = Color(0xFFFF2D78);
  static const Color magenta = Color(0xFFFF00FF);

  static const Color black = Color(0xFF000000);
  static const Color textPrimary = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color background = Color(0xFFFAFAFA);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, magenta],
  );

  static const LinearGradient circleGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, magenta],
  );

  static const LinearGradient circleGradient2 = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [pink, Color(0x4DFF2D78)],
  );
}
