import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.cinzelDecorative(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
    letterSpacing: 2.0,
  );

  static TextStyle get displayMedium => GoogleFonts.cinzelDecorative(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  static TextStyle get titleLarge => GoogleFonts.cinzelDecorative(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
  );

  static TextStyle get bodyLarge => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodySmall => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static TextStyle get labelMystic => GoogleFonts.cinzelDecorative(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.purple,
    letterSpacing: 1.5,
  );
}
