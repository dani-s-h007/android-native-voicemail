import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';

/// Material 3 Filter Chip with counter badge and accessible semantics.
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

    return Semantics(
      selected: selected,
      label: count != null ? '$label, $count items' : label,
      child: FilterChip(
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
      ),
    );
  }
}

/// Material 3 Action Chip for quick contextual actions.
class AppActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? avatar;
  final String? tooltip;

  const AppActionChip({
    super.key,
    required this.label,
    this.onPressed,
    this.avatar,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      tooltip: tooltip,
      child: ActionChip(
        avatar: avatar,
        label: Text(label),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

/// Material 3 Choice Chip for single-selection sets.
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;

  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        avatar: avatar,
        onSelected: onSelected,
      ),
    );
  }
}

/// Material 3 Input Chip for discrete pieces of user input (e.g. phone numbers, tags).
class AppInputChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final VoidCallback? onPressed;
  final Widget? avatar;
  final String? deleteButtonTooltip;

  const AppInputChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
    this.onPressed,
    this.avatar,
    this.deleteButtonTooltip = 'Remove',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: selected,
      child: InputChip(
        label: Text(label),
        selected: selected,
        avatar: avatar,
        onSelected: onSelected,
        onPressed: onPressed,
        onDeleted: onDeleted,
        deleteButtonTooltipMessage: deleteButtonTooltip,
      ),
    );
  }
}

/// Horizontal scroll bar container for chips with standard edge padding.
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
