import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;
  final int? count;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.avatar,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return FilterChip(
      selected: selected,
      avatar: avatar,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: context.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? colorScheme.secondaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onSelected: onSelected,
    );
  }
}

class AppFilterBar extends StatelessWidget {
  final List<Widget> chips;
  final EdgeInsetsGeometry padding;

  const AppFilterBar({
    super.key,
    required this.chips,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i < chips.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

