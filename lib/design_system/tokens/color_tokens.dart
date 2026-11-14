import 'package:flutter/material.dart';

abstract class AppColors {
  /// Default Google Material 3 Seed Color (Material You Blue)
  static const Color brandSeed = Color(0xFF0B57D0);

  /// Status Colors for Carrier & Device Reliability
  static const Color statusSuccess = Color(0xFF146C2E);
  static const Color statusSuccessContainer = Color(0xFFC4EED0);
  static const Color onStatusSuccessContainer = Color(0xFF00210B);

  static const Color statusWarning = Color(0xFF8F4C00);
  static const Color statusWarningContainer = Color(0xFFFFDCC1);
  static const Color onStatusWarningContainer = Color(0xFF2E1500);

  static const Color statusError = Color(0xFFBA1A1A);
  static const Color statusErrorContainer = Color(0xFFFFDAD6);
  static const Color onStatusErrorContainer = Color(0xFF410002);

  static const Color statusInfo = Color(0xFF00639B);
  static const Color statusInfoContainer = Color(0xFFCEE5FF);
  static const Color onStatusInfoContainer = Color(0xFF001D33);

  /// Dark Mode Specific Tonal Variants
  static const Color statusSuccessDark = Color(0xFF6CDB87);
  static const Color statusWarningDark = Color(0xFFFFB77C);
  static const Color statusErrorDark = Color(0xFFFFB4AB);
  static const Color statusInfoDark = Color(0xFF96CCFF);

  /// Neutral Surface Colors
  static const Color neutral10 = Color(0xFF1A1C1E);
  static const Color neutral20 = Color(0xFF2F3033);
  static const Color neutral90 = Color(0xFFE2E2E6);
  static const Color neutral95 = Color(0xFFF1F0F4);
  static const Color neutral99 = Color(0xFFFDFCFF);
}

