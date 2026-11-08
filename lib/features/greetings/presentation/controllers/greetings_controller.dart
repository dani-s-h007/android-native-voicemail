import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/features/greetings/domain/greeting_preset.dart';

class GreetingsState {
  final GreetingPreset activeGreeting;
  final List<GreetingPreset> presets;
  final bool isPlayingPreview;
  final String selectedLanguage;
  final String selectedGroup;

  const GreetingsState({
    required this.activeGreeting,
    this.presets = const [],
    this.isPlayingPreview = false,
    this.selectedLanguage = 'English (India)',
    this.selectedGroup = 'All Callers',
  });

  GreetingsState copyWith({
    GreetingPreset? activeGreeting,
    List<GreetingPreset>? presets,
    bool? isPlayingPreview,
    String? selectedLanguage,
    String? selectedGroup,
  }) {
    return GreetingsState(
      activeGreeting: activeGreeting ?? this.activeGreeting,
      presets: presets ?? this.presets,
      isPlayingPreview: isPlayingPreview ?? this.isPlayingPreview,
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
  final FlutterTts _tts = FlutterTts();

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
      if (savedText != null && savedText.isNotEmpty) {
        final current = state.activeGreeting;
        state = state.copyWith(
          activeGreeting: GreetingPreset(
            id: current.id,
            title: current.title,
            text: savedText,
            language: savedLang ?? current.language,
            assignedGroup: current.assignedGroup,
          ),
          selectedLanguage: savedLang ?? state.selectedLanguage,
        );
      }
    } catch (_) {}
  }

  Future<void> _persistGreeting(String text, String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_greeting_text', text);
      await prefs.setString('active_greeting_language', lang);
    } catch (_) {}
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      _tts.setCompletionHandler(() {
        state = state.copyWith(isPlayingPreview: false);
      });
    } catch (_) {}
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
    try {
      if (lang == 'Hindi') {
        _tts.setLanguage('hi-IN');
      } else if (lang == 'Malayalam') {
        _tts.setLanguage('ml-IN');
      } else if (lang == 'Tamil') {
        _tts.setLanguage('ta-IN');
      } else if (lang == 'Telugu') {
        _tts.setLanguage('te-IN');
      } else if (lang == 'Kannada') {
        _tts.setLanguage('kn-IN');
      } else {
        _tts.setLanguage('en-IN');
      }
    } catch (_) {}
  }

  void setGroup(String group) {
    state = state.copyWith(selectedGroup: group);
  }

  Future<void> playPreview() async {
    if (state.isPlayingPreview) {
      await _tts.stop();
      state = state.copyWith(isPlayingPreview: false);
    } else {
      state = state.copyWith(isPlayingPreview: true);
      final textToSpeak = state.activeGreeting.text
          .replaceAll('{name}', 'Danish')
          .replaceAll('{caller}', 'Friend')
          .replaceAll('{time_back}', '4 PM');
      try {
        await _tts.speak(textToSpeak);
      } catch (_) {
        state = state.copyWith(isPlayingPreview: false);
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

