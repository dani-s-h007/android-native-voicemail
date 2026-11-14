import 'package:flutter/material.dart';

class AppSegment<T> {
  final T value;
  final String label;
  final Widget? icon;

  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppSegmentedButton<T> extends StatelessWidget {
  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelectionChanged;
  final bool multiSelectionEnabled;

  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: segments.map((s) {
        return ButtonSegment<T>(
          value: s.value,
          label: Text(s.label),
          icon: s.icon,
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (newSelection) {
        if (newSelection.isNotEmpty) {
          onSelectionChanged(newSelection.first);
        }
      },
      showSelectedIcon: true,
    );
  }
}

