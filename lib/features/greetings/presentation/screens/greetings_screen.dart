import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/greetings/domain/greeting_preset.dart';
import 'package:voicemail/features/greetings/presentation/controllers/greetings_controller.dart';

class GreetingsScreen extends ConsumerStatefulWidget {
  const GreetingsScreen({super.key});

  @override
  ConsumerState<GreetingsScreen> createState() => _GreetingsScreenState();
}

class _GreetingsScreenState extends ConsumerState<GreetingsScreen> {
  late final TextEditingController _textController;

  final List<String> _languages = [
    'English (India)',
    'Hindi',
    'Malayalam',
    'Tamil',
    'Telugu',
    'Kannada',
  ];

  final List<String> _contactGroups = [
    'All Callers',
    'Work & Clients',
    'College & Classmates',
    'Family & Friends',
  ];

  @override
  void initState() {
    super.initState();
    final greeting = ref.read(greetingsControllerProvider).activeGreeting;
    _textController = TextEditingController(text: greeting.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _insertVariable(String variable) {
    final text = _textController.text;
    final selection = _textController.selection;
    final newText = text.replaceRange(
      selection.start >= 0 ? selection.start : text.length,
      selection.end >= 0 ? selection.end : text.length,
      variable,
    );
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: (selection.start >= 0 ? selection.start : text.length) + variable.length,
    );
    ref.read(greetingsControllerProvider.notifier).updateText(newText);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(greetingsControllerProvider);
    final controller = ref.read(greetingsControllerProvider.notifier);
    final colorScheme = context.colorScheme;

    // Sync controller if preset changed externally
    if (_textController.text != state.activeGreeting.text) {
      _textController.text = state.activeGreeting.text;
    }

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Custom Greetings Hub',
        subtitle: 'Audio Prompts & Multilingual Voices',
        showBackButton: false,
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          // 1. Active Greeting Preview Card
          AppCard(
            variant: AppCardVariant.filled,
            color: colorScheme.primaryContainer.withValues(alpha: 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, color: colorScheme.primary, size: 20),
                        AppSpacing.hSpace8,
                        Text(
                          state.activeGreeting.title,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        state.selectedLanguage,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpace12,
                Text(
                  '"${state.activeGreeting.text}"',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                AppSpacing.vSpace16,
                Row(
                  children: [
                    FilledButton.icon(
                      icon: Icon(
                        state.isPlayingPreview ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        state.isPlayingPreview ? 'Stop Voice' : 'Listen to Preview (TTS)',
                      ),
                      onPressed: controller.playPreview,
                    ),
                    AppSpacing.hSpace12,
                    Chip(
                      label: Text('Group: ${state.selectedGroup}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vSpace20,

          // 2. Preset Selection Chips
          Text(
            'CHOOSE PRESET PROMPT',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.presets.map((preset) {
              final isSelected = state.activeGreeting.id == preset.id;
              return ChoiceChip(
                selected: isSelected,
                label: Text(preset.title),
                onSelected: (_) {
                  controller.selectPreset(preset);
                  _textController.text = preset.text;
                },
              );
            }).toList(),
          ),
          AppSpacing.vSpace20,

          // 3. Greeting Text Editor
          Text(
            'EDIT GREETING SCRIPT',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,

          // Variable Insertion Chips
          Row(
            children: [
              Text('Insert variable:', style: context.textTheme.bodySmall),
              AppSpacing.hSpace8,
              ActionChip(
                label: const Text('{name}'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _insertVariable('{name}'),
              ),
              AppSpacing.hSpace6,
              ActionChip(
                label: const Text('{caller}'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _insertVariable('{caller}'),
              ),
              AppSpacing.hSpace6,
              ActionChip(
                label: const Text('{time_back}'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _insertVariable('{time_back}'),
              ),
            ],
          ),
          AppSpacing.vSpace8,

          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter your custom greeting prompt for callers...',
            ),
            onChanged: controller.updateText,
          ),
          AppSpacing.vSpace20,

          // 4. Voice / Language Selector
          Text(
            'LANGUAGE & ACCENT',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          DropdownButtonFormField<String>(
            value: state.selectedLanguage,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.language),
              labelText: 'Voice Language',
            ),
            items: _languages.map((l) {
              return DropdownMenuItem(value: l, child: Text(l));
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.setLanguage(val);
            },
          ),
          AppSpacing.vSpace20,

          // 5. Per-Contact-Group Assignment
          Text(
            'ASSIGN TO CALLER GROUP',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          DropdownButtonFormField<String>(
            value: state.selectedGroup,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.group_outlined),
              labelText: 'Caller Group',
            ),
            items: _contactGroups.map((g) {
              return DropdownMenuItem(value: g, child: Text(g));
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.setGroup(val);
            },
          ),
          AppSpacing.vSpace24,

          // 6. Save Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Greeting on Device'),
            onPressed: () {
              context.showSnackBar('Greeting saved locally on device!');
            },
          ),
          AppSpacing.vSpace24,
        ],
      ),
    );
  }
}
