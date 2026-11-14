import 'package:flutter/material.dart';

abstract class AppShapes {
  static const double radiusNone = 0.0;
  static const double radiusExtraSmall = 4.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 28.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedNone = BorderRadius.all(Radius.circular(radiusNone));
  static const BorderRadius roundedExtraSmall = BorderRadius.all(Radius.circular(radiusExtraSmall));
  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedExtraLarge = BorderRadius.all(Radius.circular(radiusExtraLarge));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

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
