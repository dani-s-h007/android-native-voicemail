import 'package:flutter/material.dart';

abstract class AppMotion {
  // Durations
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);

  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);

  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);

  // Curves (Material 3 standard easing tokens)
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve standardDecelerate = Curves.easeOutCubic;
  static const Curve standardAccelerate = Curves.easeInCubic;
}

