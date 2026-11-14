import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/tokens/shape_tokens.dart';

class AppDialog extends StatelessWidget {
  final Widget? icon;
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    this.icon,
    required this.title,
    required this.content,
    this.actions,
  });

  static Future<bool?> showConfirmation({
    required BuildContext context,
    Widget? icon,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: icon,
        title: title,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: ctx.colorScheme.error,
                    foregroundColor: ctx.colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: AppShapes.dialogShape,
      icon: icon,
      title: Text(
        title,
        textAlign: icon != null ? TextAlign.center : TextAlign.start,
      ),
      content: content,
      actions: actions,
    );
  }
}

