import 'package:flutter/material.dart';

abstract class AppShapes {
  static const double radiusNone = 0.0;
  static const double radiusExtraSmall = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 28.0;
  static const double radiusFull = 999.0;

  static final BorderRadius roundedNone = BorderRadius.circular(radiusNone);
  static final BorderRadius roundedExtraSmall = BorderRadius.circular(radiusExtraSmall);
  static final BorderRadius roundedSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius roundedMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius roundedLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius roundedExtraLarge = BorderRadius.circular(radiusExtraLarge);
  static final BorderRadius roundedFull = BorderRadius.circular(radiusFull);

  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
  );

  static const RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusExtraLarge)),
  );

  static const RoundedRectangleBorder chipShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusSmall)),
  );

  static const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusFull)),
  );
}

