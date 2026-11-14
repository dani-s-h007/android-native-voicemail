import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/tokens/color_tokens.dart';
import 'package:voicemail/design_system/tokens/shape_tokens.dart';

enum AppBannerType { success, warning, error, info }

class AppStatusBanner extends StatelessWidget {
  final String title;
  final String? message;
  final AppBannerType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const AppStatusBanner({
    super.key,
    required this.title,
    this.message,
    this.type = AppBannerType.warning,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    Color bg;
    Color fg;
    Color border;
    IconData icon;

    switch (type) {
      case AppBannerType.success:
        bg = isDark ? AppColors.statusSuccessDark.withValues(alpha: 0.15) : AppColors.statusSuccessContainer;
        fg = isDark ? AppColors.statusSuccessDark : AppColors.onStatusSuccessContainer;
        border = isDark ? AppColors.statusSuccessDark.withValues(alpha: 0.3) : AppColors.statusSuccess;
        icon = Icons.check_circle_outline;
      case AppBannerType.warning:
        bg = isDark ? AppColors.statusWarningDark.withValues(alpha: 0.15) : AppColors.statusWarningContainer;
        fg = isDark ? AppColors.statusWarningDark : AppColors.onStatusWarningContainer;
        border = isDark ? AppColors.statusWarningDark.withValues(alpha: 0.3) : AppColors.statusWarning;
        icon = Icons.warning_amber_rounded;
      case AppBannerType.error:
        bg = isDark ? AppColors.statusErrorDark.withValues(alpha: 0.15) : AppColors.statusErrorContainer;
        fg = isDark ? AppColors.statusErrorDark : AppColors.onStatusErrorContainer;
        border = isDark ? AppColors.statusErrorDark.withValues(alpha: 0.3) : AppColors.statusError;
        icon = Icons.error_outline;
      case AppBannerType.info:
        bg = isDark ? AppColors.statusInfoDark.withValues(alpha: 0.15) : AppColors.statusInfoContainer;
        fg = isDark ? AppColors.statusInfoDark : AppColors.onStatusInfoContainer;
        border = isDark ? AppColors.statusInfoDark.withValues(alpha: 0.3) : AppColors.statusInfo;
        icon = Icons.info_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppShapes.roundedLarge,
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: fg.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
          if (onDismiss != null) ...[
            IconButton(
              icon: Icon(Icons.close, size: 18, color: fg),
              onPressed: onDismiss,
              tooltip: 'Dismiss banner',
            ),
          ],
        ],
      ),
    );
  }
}

