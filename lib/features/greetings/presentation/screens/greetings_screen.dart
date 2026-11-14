import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/greetings/presentation/controllers/greetings_controller.dart';

class GreetingsScreen extends ConsumerStatefulWidget {
  const GreetingsScreen({super.key});

  @override
  ConsumerState<GreetingsScreen> createState() => _GreetingsScreenState();
}

class _GreetingsScreenState extends ConsumerState<GreetingsScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textController;
  late final TabController _tabController;

  final List<String> _contactGroups = [
    'All Callers',
    'Work & Clients',
    'Family & VIP',
    'Unknown / Spam',
  ];

  @override
  void initState() {
    super.initState();
    final greeting = ref.read(greetingsControllerProvider).activeGreeting;
    _textController = TextEditingController(text: greeting.text);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _insertVariable(String variable) {
    final text = _textController.text;
    final selection = _textController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, variable);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: start + variable.length,
    );
    ref.read(greetingsControllerProvider.notifier).updateText(newText);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(greetingsControllerProvider);
    final controller = ref.read(greetingsControllerProvider.notifier);
    final colorScheme = context.colorScheme;

    // Keep text controller synchronized when preset changes externally
    if (_textController.text != state.activeGreeting.text &&
        !FocusScope.of(context).hasFocus) {
      _textController.text = state.activeGreeting.text;
    }

    final supportedLanguages = AppConfig.supportedLanguages
        .map((l) => l.displayName)
        .toList();
    if (!supportedLanguages.contains(state.selectedLanguage)) {
      supportedLanguages.add(state.selectedLanguage);
    }

    final groups = List<String>.from(_contactGroups);
    if (!groups.contains(state.selectedGroup)) {
      groups.add(state.selectedGroup);
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Custom Greetings Hub',
        subtitle: 'Audio Prompts & Multilingual Voices',
        showBackButton: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.record_voice_over_outlined),
              text: 'Smart TTS & Presets',
            ),
            Tab(
              icon: Icon(Icons.mic_none_outlined),
              text: 'Record Voice',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Smart TTS & Presets
          _buildTtsTab(context, state, controller, colorScheme, supportedLanguages, groups),

          // TAB 2: Voice Studio / Recording
          _buildVoiceRecordingTab(context, state, controller, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTtsTab(
    BuildContext context,
    GreetingsState state,
    GreetingsController controller,
    ColorScheme colorScheme,
    List<String> supportedLanguages,
    List<String> groups,
  ) {
    return ListView(
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  Chip(
                    avatar: const Icon(Icons.people_outline, size: 16),
                    label: Text(state.selectedGroup),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
              AppSpacing.hSpace6,
              ActionChip(
                label: const Text('{alternative_number}'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _insertVariable('{alternative_number}'),
              ),
            ],
          ),
        ),
        AppSpacing.vSpace8,

        TextField(
          controller: _textController,
          maxLines: 4,
          maxLength: 350,
          decoration: const InputDecoration(
            hintText: 'Enter your custom greeting prompt for callers...',
            helperText: 'Variables like {name} and {time_back} will be filled dynamically.',
          ),
          onChanged: controller.updateText,
        ),
        AppSpacing.vSpace16,

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
          key: ValueKey(state.selectedLanguage),
          initialValue: state.selectedLanguage,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.language),
            labelText: 'Voice Language',
          ),
          items: supportedLanguages.map((l) {
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
          key: ValueKey(state.selectedGroup),
          initialValue: state.selectedGroup,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.group_outlined),
            labelText: 'Caller Group',
          ),
          items: groups.map((g) {
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
    );
  }

  Widget _buildVoiceRecordingTab(
    BuildContext context,
    GreetingsState state,
    GreetingsController controller,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: AppSpacing.padding16,
      children: [
        AppCard(
          variant: AppCardVariant.outlined,
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: state.isRecording
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.isRecording ? Icons.mic : Icons.mic_none,
                  size: 48,
                  color: state.isRecording
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              AppSpacing.vSpace16,
              Text(
                state.isRecording
                    ? 'Recording Voice Greeting...'
                    : (state.recordedAudioPath != null
                        ? 'Custom Voice Greeting Saved'
                        : 'Record Your Natural Voice'),
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.vSpace4,
              Text(
                state.isRecording
                    ? 'Speak clearly into the microphone. Tap Stop when finished.'
                    : (state.recordedAudioPath != null
                        ? 'Callers will hear this recording instead of text-to-speech.'
                        : 'Leave a personalized message in your own authentic voice.'),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vSpace20,
              if (state.isRecording) ...[
                const LinearProgressIndicator(),
                AppSpacing.vSpace16,
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  onPressed: () {
                    controller.stopRecording();
                    context.showSnackBar('Voice greeting recorded successfully.');
                  },
                ),
              ] else if (state.recordedAudioPath != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Recording'),
                      onPressed: () {
                        context.showSnackBar('Playing recorded audio preview...');
                      },
                    ),
                    AppSpacing.hSpace12,
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-record'),
                      onPressed: () {
                        controller.startRecording();
                      },
                    ),
                  ],
                ),
                AppSpacing.vSpace12,
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Voice Recording'),
                  onPressed: () {
                    controller.clearRecordedAudio();
                    context.showSnackBar('Voice recording deleted. Reverted to TTS prompt.');
                  },
                ),
              ] else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Recording'),
                  onPressed: () {
                    controller.startRecording();
                  },
                ),
              ],
            ],
          ),
        ),
        AppSpacing.vSpace20,
        AppCard(
          variant: AppCardVariant.filled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: colorScheme.primary, size: 20),
                  AppSpacing.hSpace8,
                  Text(
                    'Audio Quality Tips',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpace8,
              Text(
                '• Keep the phone 6-8 inches away from your mouth.\n'
                '• Record in a quiet room with minimal background noise.\n'
                '• Keep your greeting concise (under 20 seconds) so callers can leave their message promptly.',
                style: context.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
