import 'package:flutter/material.dart';

abstract class AppSpacing {
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // EdgeInsets presets
  static const EdgeInsets padding4 = EdgeInsets.all(space4);
  static const EdgeInsets padding8 = EdgeInsets.all(space8);
  static const EdgeInsets padding12 = EdgeInsets.all(space12);
  static const EdgeInsets padding16 = EdgeInsets.all(space16);
  static const EdgeInsets padding24 = EdgeInsets.all(space24);
  static const EdgeInsets padding32 = EdgeInsets.all(space32);

  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(horizontal: space16);
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(horizontal: space24);
  static const EdgeInsets vertical8 = EdgeInsets.symmetric(vertical: space8);
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(vertical: space16);

  // SizedBox vertical spacing helpers
  static const SizedBox vSpace2 = SizedBox(height: 2.0);
  static const SizedBox vSpace4 = SizedBox(height: space4);
  static const SizedBox vSpace6 = SizedBox(height: 6.0);
  static const SizedBox vSpace8 = SizedBox(height: space8);
  static const SizedBox vSpace10 = SizedBox(height: 10.0);
  static const SizedBox vSpace12 = SizedBox(height: space12);
  static const SizedBox vSpace16 = SizedBox(height: space16);
  static const SizedBox vSpace20 = SizedBox(height: space20);
  static const SizedBox vSpace24 = SizedBox(height: space24);
  static const SizedBox vSpace32 = SizedBox(height: space32);
  static const SizedBox vSpace48 = SizedBox(height: space48);

  // SizedBox horizontal spacing helpers
  static const SizedBox hSpace4 = SizedBox(width: space4);
  static const SizedBox hSpace6 = SizedBox(width: 6.0);
  static const SizedBox hSpace8 = SizedBox(width: space8);
  static const SizedBox hSpace12 = SizedBox(width: space12);
  static const SizedBox hSpace14 = SizedBox(width: 14.0);
  static const SizedBox hSpace16 = SizedBox(width: space16);
  static const SizedBox hSpace24 = SizedBox(width: space24);
  static const SizedBox hSpace32 = SizedBox(width: space32);
}

