import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton && canPop) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
      );
    }

    return AppBar(
      leading: leadingWidget,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                Text(
                  subtitle!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : Text(title),
      actions: actions,
      bottom: bottom,
    );
  }
}

class AppLargeSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final PreferredSizeWidget? bottom;

  const AppLargeSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      title: Text(title),
      actions: actions,
      leading: leading,
      pinned: pinned,
      floating: floating,
      bottom: bottom,
    );
  }
}

