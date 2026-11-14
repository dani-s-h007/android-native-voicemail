import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/tokens/elevation_tokens.dart';
import 'package:voicemail/design_system/tokens/shape_tokens.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

enum AppCardVariant { filled, elevated, outlined }

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.variant = AppCardVariant.filled,
    this.padding = AppSpacing.padding16,
    this.color,
    this.borderRadius,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final radius = borderRadius ?? AppShapes.roundedLarge;

    Color cardColor;
    double elevation;
    BorderSide side;

    switch (variant) {
      case AppCardVariant.filled:
        cardColor = color ?? colorScheme.surfaceContainerLow;
        elevation = AppElevation.level0;
        side = borderSide ?? BorderSide.none;
      case AppCardVariant.elevated:
        cardColor = color ?? colorScheme.surfaceContainerLow;
        elevation = AppElevation.level1;
        side = borderSide ?? BorderSide.none;
      case AppCardVariant.outlined:
        cardColor = color ?? colorScheme.surface;
        elevation = AppElevation.level0;
        side = borderSide ?? BorderSide(color: colorScheme.outlineVariant);
    }

    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: side,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

