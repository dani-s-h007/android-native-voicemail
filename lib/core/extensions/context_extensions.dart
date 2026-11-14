import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;

  /// Material 3 Responsive Breakpoints
  bool get isCompact => screenWidth < 600;
  bool get isMedium => screenWidth >= 600 && screenWidth < 840;
  bool get isExpanded => screenWidth >= 840;

  void showSnackBar(String message, {Duration duration = const Duration(seconds: 4)}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

