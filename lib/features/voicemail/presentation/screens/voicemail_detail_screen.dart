import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/extensions/datetime_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/shape_tokens.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';
import 'package:voicemail/features/voicemail/presentation/controllers/voicemail_controller.dart';

class VoicemailDetailScreen extends ConsumerStatefulWidget {
  final String voicemailId;

  const VoicemailDetailScreen({
    super.key,
    required this.voicemailId,
  });

  @override
  ConsumerState<VoicemailDetailScreen> createState() => _VoicemailDetailScreenState();
}

class _VoicemailDetailScreenState extends ConsumerState<VoicemailDetailScreen> {
  // Audio Player State Simulation
  bool _isPlaying = false;
  double _playbackPosition = 0.0; // in seconds
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;

  final List<double> _speedOptions = [0.5, 1.0, 1.25, 1.5, 2.0];

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback(int totalDuration) {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback(totalDuration);
    }
  }

  void _startPlayback(int totalDuration) {
    setState(() => _isPlaying = true);
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _playbackPosition += 0.1 * _playbackSpeed;
        if (_playbackPosition >= totalDuration) {
          _playbackPosition = 0.0;
          _isPlaying = false;
          _playbackTimer?.cancel();
        }
      });
    });
  }

  void _pausePlayback() {
    setState(() => _isPlaying = false);
    _playbackTimer?.cancel();
  }

  void _seekTo(double seconds, int totalDuration) {
    setState(() {
      _playbackPosition = seconds.clamp(0.0, totalDuration.toDouble());
    });
  }

  void _skipSeconds(double delta, int totalDuration) {
    _seekTo(_playbackPosition + delta, totalDuration);
  }

  Future<void> _callBack(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) context.showErrorSnackBar('Unable to launch dialer');
    }
  }

  Future<void> _shareVoicemail(Voicemail vm) async {
    final text = 'Voicemail from ${vm.displayName} (${vm.callerNumber}):\n\n'
        '${vm.transcriptText ?? "No transcript available."}\n\n'
        'Recorded via Vani Voicemail (https://danishk.web.app)';
    await Share.share(text, subject: 'Voicemail Transcript');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voicemailControllerProvider);
    final controller = ref.read(voicemailControllerProvider.notifier);
    final colorScheme = context.colorScheme;

    final vm = state.voicemails.cast<Voicemail?>().firstWhere(
          (v) => v?.id == widget.voicemailId,
          orElse: () => null,
        );

    if (vm == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Voicemail'),
        body: AppErrorState(
          message: 'This voicemail could not be found or was deleted.',
          onRetry: () => context.pop(),
          retryLabel: 'Go Back',
        ),
      );
    }

    final totalSeconds = vm.durationSeconds > 0 ? vm.durationSeconds : 30;
    final currentDuration = Duration(seconds: _playbackPosition.toInt());
    final remainingDuration = Duration(seconds: (totalSeconds - _playbackPosition).toInt().clamp(0, totalSeconds));

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Voicemail Details',
        actions: [
          IconButton(
            icon: Icon(
              vm.isStarred ? Icons.star : Icons.star_border,
              color: vm.isStarred ? Colors.amber.shade700 : null,
            ),
            tooltip: vm.isStarred ? 'Unstar' : 'Star',
            onPressed: () => controller.toggleStarred(vm.id, vm.isStarred),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _shareVoicemail(vm),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () async {
              final confirmed = await AppDialog.showConfirmation(
                context: context,
                title: 'Delete Voicemail?',
                message: 'Permanently remove recording from ${vm.displayName}?',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirmed == true) {
                await controller.deleteSingle(vm.id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          // 1. Caller Profile Card
          AppCard(
            variant: AppCardVariant.filled,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(
                    vm.initials,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                AppSpacing.hSpace16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.displayName,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      AppSpacing.vSpace4,
                      Text(
                        vm.callerNumber,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vSpace4,
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            vm.createdAt.formattedDateTime,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: colorScheme.outline)),
                          const SizedBox(width: 8),
                          Text(
                            vm.callHandlingMode,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // 2. Action Toolbar (Call back, SMS, WhatsApp)
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.call),
                  label: const Text('Call Back'),
                  onPressed: () => _callBack(vm.callerNumber),
                ),
              ),
              AppSpacing.hSpace12,
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('SMS / Chat'),
                  onPressed: () => _callBack(vm.callerNumber),
                ),
              ),
            ],
          ),
          AppSpacing.vSpace16,

          // 3. Audio Player Box
          AppCard(
            variant: AppCardVariant.outlined,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Timeline Scrubber
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _playbackPosition.clamp(0.0, totalSeconds.toDouble()),
                    min: 0.0,
                    max: totalSeconds.toDouble(),
                    onChanged: (val) => _seekTo(val, totalSeconds),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentDuration.formattedMinutesSeconds,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '-${remainingDuration.formattedMinutesSeconds}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace12,

                // Audio Controls (Skip -10s, Play/Pause, Skip +10s, Speed selector)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Speed selector button
                    PopupMenuButton<double>(
                      initialValue: _playbackSpeed,
                      tooltip: 'Playback Speed',
                      onSelected: (speed) {
                        setState(() => _playbackSpeed = speed);
                      },
                      itemBuilder: (context) => _speedOptions.map((s) {
                        return PopupMenuItem<double>(
                          value: s,
                          child: Text('${s}x', style: TextStyle(
                            fontWeight: s == _playbackSpeed ? FontWeight.bold : FontWeight.normal,
                          )),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),

                    // Skip -10s
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, size: 30),
                      tooltip: 'Skip backward 10s',
                      onPressed: () => _skipSeconds(-10.0, totalSeconds),
                    ),

                    // Play / Pause FAB
                    FloatingActionButton(
                      elevation: 1,
                      onPressed: () => _togglePlayback(totalSeconds),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 34),
                    ),

                    // Skip +10s
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, size: 30),
                      tooltip: 'Skip forward 10s',
                      onPressed: () => _skipSeconds(10.0, totalSeconds),
                    ),

                    // Speaker Output Icon
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined),
                      tooltip: 'Bottom Loudspeaker Active',
                      onPressed: () {
                        context.showSnackBar('Playing via media loudspeaker');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // 4. Interactive Transcript Card
          AppCard(
            variant: AppCardVariant.filled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.transcribe_rounded, color: colorScheme.primary, size: 20),
                        AppSpacing.hSpace8,
                        Text(
                          'Interactive Transcript',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (vm.detectedLanguage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vm.detectedLanguage!,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.vSpace12,
                _buildInteractiveTranscript(vm.transcriptText, _playbackPosition, totalSeconds),
                AppSpacing.vSpace16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Text'),
                      onPressed: () {
                        if (vm.transcriptText != null) {
                          Clipboard.setData(ClipboardData(text: vm.transcriptText!));
                          context.showSnackBar('Transcript copied to clipboard');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // 5. Security & Privacy Safeguard Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppShapes.roundedMedium,
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, size: 18, color: colorScheme.outline),
                AppSpacing.hSpace12,
                Expanded(
                  child: Text(
                    'Stored strictly on-device in SQLite. No remote server backup.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace24,
        ],
      ),
    );
  }

  Widget _buildInteractiveTranscript(
    String? fullText,
    double position,
    int totalDuration,
  ) {
    if (fullText == null || fullText.isEmpty) {
      return Text(
        'No transcript available for this message.',
        style: TextStyle(fontStyle: FontStyle.italic, color: context.colorScheme.outline),
      );
    }

    final words = fullText.split(' ');
    final progressFraction = totalDuration > 0 ? (position / totalDuration).clamp(0.0, 1.0) : 0.0;
    final highlightedIndex = (progressFraction * words.length).toInt();

    return RichText(
      text: TextSpan(
        style: context.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: context.colorScheme.onSurfaceVariant,
        ),
        children: List.generate(words.length, (i) {
          final isSpoken = i <= highlightedIndex && _isPlaying;
          return TextSpan(
            text: '${words[i]} ',
            style: TextStyle(
              color: isSpoken ? context.colorScheme.primary : context.colorScheme.onSurface,
              fontWeight: isSpoken ? FontWeight.bold : FontWeight.normal,
              backgroundColor: isSpoken
                  ? context.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }
}

