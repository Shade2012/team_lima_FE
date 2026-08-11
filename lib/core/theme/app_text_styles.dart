import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle logo = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  static TextStyle title = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static TextStyle subtitle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle link = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle linkSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static TextStyle hint = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle snackbar = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
}
