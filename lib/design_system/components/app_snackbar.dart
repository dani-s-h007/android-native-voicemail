import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/tokens/color_tokens.dart';
import 'package:voicemail/design_system/tokens/shape_tokens.dart';

enum AppSnackbarType { info, success, warning, error }

/// Material 3 Floating Snackbar with consistent typography, iconography, and contrast.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    Color bg;
    Color fg;
    IconData icon;

    switch (type) {
      case AppSnackbarType.success:
        bg = isDark ? AppColors.statusSuccessDark : AppColors.statusSuccess;
        fg = Colors.white;
        icon = Icons.check_circle_outline;
      case AppSnackbarType.warning:
        bg = isDark ? AppColors.statusWarningDark : const Color(0xFFE65100);
        fg = Colors.white;
        icon = Icons.warning_amber_rounded;
      case AppSnackbarType.error:
        bg = colorScheme.error;
        fg = colorScheme.onError;
        icon = Icons.error_outline;
      case AppSnackbarType.info:
        bg = isDark ? colorScheme.surfaceContainerHighest : colorScheme.inverseSurface;
        fg = isDark ? colorScheme.onSurface : colorScheme.onInverseSurface;
        icon = Icons.info_outline;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: AppShapes.roundedMedium,
        ),
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: fg,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
