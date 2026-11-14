import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/features/greetings/domain/greeting_preset.dart';

class GreetingsState {
  final GreetingPreset activeGreeting;
  final List<GreetingPreset> presets;
  final bool isPlayingPreview;
  final bool isRecording;
  final String? recordedAudioPath;
  final Duration recordingDuration;
  final String selectedLanguage;
  final String selectedGroup;

  const GreetingsState({
    required this.activeGreeting,
    this.presets = const [],
    this.isPlayingPreview = false,
    this.isRecording = false,
    this.recordedAudioPath,
    this.recordingDuration = Duration.zero,
    this.selectedLanguage = 'English',
    this.selectedGroup = 'All Callers',
  });

  GreetingsState copyWith({
    GreetingPreset? activeGreeting,
    List<GreetingPreset>? presets,
    bool? isPlayingPreview,
    bool? isRecording,
    String? recordedAudioPath,
    bool clearRecordedAudio = false,
    Duration? recordingDuration,
    String? selectedLanguage,
    String? selectedGroup,
  }) {
    return GreetingsState(
      activeGreeting: activeGreeting ?? this.activeGreeting,
      presets: presets ?? this.presets,
      isPlayingPreview: isPlayingPreview ?? this.isPlayingPreview,
      isRecording: isRecording ?? this.isRecording,
      recordedAudioPath: clearRecordedAudio
          ? null
          : (recordedAudioPath ?? this.recordedAudioPath),
      recordingDuration: recordingDuration ?? this.recordingDuration,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}

final greetingsControllerProvider =
    StateNotifierProvider<GreetingsController, GreetingsState>((ref) {
  return GreetingsController();
});

class GreetingsController extends StateNotifier<GreetingsState> {
  FlutterTts? _tts;

  GreetingsController()
      : super(
          GreetingsState(
            activeGreeting: GreetingPreset.defaultPresets.first,
            presets: GreetingPreset.defaultPresets,
          ),
        ) {
    _initTts();
    _loadSavedGreeting();
  }

  Future<void> _loadSavedGreeting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedText = prefs.getString('active_greeting_text');
      final savedLang = prefs.getString('active_greeting_language');
      final savedGroup = prefs.getString('active_greeting_group');
      final recordedPath = prefs.getString('active_greeting_audio_path');

      if (savedText != null && savedText.isNotEmpty) {
        final current = state.activeGreeting;
        state = state.copyWith(
          activeGreeting: GreetingPreset(
            id: current.id,
            title: current.title,
            text: savedText,
            language: savedLang ?? current.language,
            assignedGroup: savedGroup ?? current.assignedGroup,
          ),
          selectedLanguage: savedLang ?? state.selectedLanguage,
          selectedGroup: savedGroup ?? state.selectedGroup,
          recordedAudioPath: recordedPath,
        );
      }
    } catch (_) {}
  }

  Future<void> _persistGreeting(String text, String lang, {String? audioPath}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_greeting_text', text);
      await prefs.setString('active_greeting_language', lang);
      await prefs.setString('active_greeting_group', state.selectedGroup);
      if (audioPath != null) {
        await prefs.setString('active_greeting_audio_path', audioPath);
      }
    } catch (_) {}
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-US').catchError((_) => null);
      await _tts!.setPitch(1.0).catchError((_) => null);
      await _tts!.setSpeechRate(0.5).catchError((_) => null);
      _tts!.setCompletionHandler(() {
        state = state.copyWith(isPlayingPreview: false);
      });
    } catch (_) {
      _tts = null;
    }
  }

  void selectPreset(GreetingPreset preset) {
    state = state.copyWith(
      activeGreeting: preset,
      selectedLanguage: preset.language,
      selectedGroup: preset.assignedGroup,
    );
    _persistGreeting(preset.text, preset.language);
  }

  void updateText(String newText) {
    final updated = GreetingPreset(
      id: state.activeGreeting.id,
      title: state.activeGreeting.title,
      text: newText,
      language: state.selectedLanguage,
      assignedGroup: state.selectedGroup,
    );
    state = state.copyWith(activeGreeting: updated);
    _persistGreeting(newText, state.selectedLanguage);
  }

  void setLanguage(String lang) {
    state = state.copyWith(selectedLanguage: lang);
    _persistGreeting(state.activeGreeting.text, lang);
    if (_tts == null) return;
    try {
      if (lang == 'Hindi') {
        _tts!.setLanguage('hi-IN').catchError((_) => null);
      } else if (lang == 'Malayalam') {
        _tts!.setLanguage('ml-IN').catchError((_) => null);
      } else if (lang == 'Spanish') {
        _tts!.setLanguage('es-ES').catchError((_) => null);
      } else if (lang == 'French') {
        _tts!.setLanguage('fr-FR').catchError((_) => null);
      } else if (lang == 'German') {
        _tts!.setLanguage('de-DE').catchError((_) => null);
      } else {
        _tts!.setLanguage('en-US').catchError((_) => null);
      }
    } catch (_) {}
  }

  void setGroup(String group) {
    state = state.copyWith(selectedGroup: group);
    _persistGreeting(state.activeGreeting.text, state.selectedLanguage);
  }

  Future<void> playPreview() async {
    if (state.isPlayingPreview) {
      if (_tts != null) {
        await _tts!.stop().catchError((_) => null);
      }
      state = state.copyWith(isPlayingPreview: false);
    } else {
      state = state.copyWith(isPlayingPreview: true);
      String userName = 'Me';
      try {
        final prefs = await SharedPreferences.getInstance();
        userName = prefs.getString('user_display_name') ?? 'Me';
      } catch (_) {}

      final textToSpeak = state.activeGreeting.text
          .replaceAll('{name}', userName)
          .replaceAll('{caller}', 'Caller')
          .replaceAll('{time_back}', '5:00 PM')
          .replaceAll('{alternative_number}', 'alternate line');

      if (_tts != null) {
        try {
          await _tts!.speak(textToSpeak).catchError((_) => null);
        } catch (_) {
          state = state.copyWith(isPlayingPreview: false);
        }
      } else {
        // Fallback simulation for tests/desktop
        await Future<void>.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(isPlayingPreview: false);
      }
    }
  }

  // Voice Recording simulation/controls
  void startRecording() {
    state = state.copyWith(isRecording: true, recordingDuration: Duration.zero);
  }

  void stopRecording({String? savedPath}) {
    final path = savedPath ?? 'custom_voice_greeting.m4a';
    state = state.copyWith(
      isRecording: false,
      recordedAudioPath: path,
    );
    _persistGreeting(state.activeGreeting.text, state.selectedLanguage, audioPath: path);
  }

  void clearRecordedAudio() {
    state = state.copyWith(clearRecordedAudio: true);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('active_greeting_audio_path');
    }).catchError((_) => null);
  }

  @override
  void dispose() {
    _tts?.stop().catchError((_) => null);
    super.dispose();
  }
}
