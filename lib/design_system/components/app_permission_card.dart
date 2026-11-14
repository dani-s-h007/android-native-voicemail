import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/app_card.dart';
import 'package:voicemail/design_system/tokens/color_tokens.dart';

class AppPermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback? onGrant;
  final String actionLabel;
  final bool isMandatory;

  const AppPermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    this.onGrant,
    this.actionLabel = 'Allow',
    this.isMandatory = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final badgeBg = isGranted
        ? (isDark ? AppColors.statusSuccessDark.withValues(alpha: 0.2) : AppColors.statusSuccessContainer)
        : (isMandatory
            ? (isDark ? AppColors.statusErrorDark.withValues(alpha: 0.2) : AppColors.statusErrorContainer)
            : (isDark ? AppColors.statusWarningDark.withValues(alpha: 0.2) : AppColors.statusWarningContainer));

    final badgeColor = isGranted
        ? (isDark ? AppColors.statusSuccessDark : AppColors.statusSuccess)
        : (isMandatory
            ? (isDark ? AppColors.statusErrorDark : AppColors.statusError)
            : (isDark ? AppColors.statusWarningDark : AppColors.statusWarning));

    return AppCard(
      variant: AppCardVariant.filled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isGranted ? badgeBg : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isGranted ? badgeColor : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted ? 'ACTIVE' : (isMandatory ? 'REQUIRED' : 'RECOMMENDED'),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGranted && onGrant != null) ...[
                FilledButton.tonal(
                  onPressed: onGrant,
                  child: Text(actionLabel),
                ),
              ] else if (isGranted) ...[
                Icon(
                  Icons.check_circle,
                  color: badgeColor,
                  size: 24,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

