import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';

class AppSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const AppSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return InkWell(
      onTap: enabled && onChanged != null
          ? () {
              HapticFeedback.lightImpact();
              onChanged!(!value);
            }
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: enabled
                    ? (val) {
                        HapticFeedback.lightImpact();
                        onChanged?.call(val);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

