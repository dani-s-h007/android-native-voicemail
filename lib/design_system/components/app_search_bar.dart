import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/tokens/shape_tokens.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Widget? leading;
  final List<Widget>? trailing;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search voicemails, contacts...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.leading,
    this.trailing,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppShapes.roundedFull,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          widget.leading ??
              Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: context.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: context.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (_hasText) ...[
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              tooltip: 'Clear search',
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
                widget.onClear?.call();
              },
            ),
          ],
          if (widget.trailing != null) ...widget.trailing!,
        ],
      ),
    );
  }
}

