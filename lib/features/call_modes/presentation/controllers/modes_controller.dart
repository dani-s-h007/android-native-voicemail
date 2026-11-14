import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/reliability/reliability_service.dart';
import 'package:voicemail/features/call_modes/domain/call_mode.dart';

class ModesState {
  final bool isAssistantActive;
  final CallHandlingMode currentMode;
  final DateTime? dndUntil;
  final DndSchedule dndSchedule;
  final DndExceptions exceptions;
  final bool isLoading;

  const ModesState({
    this.isAssistantActive = true,
    this.currentMode = CallHandlingMode.serverRelay,
    this.dndUntil,
    this.dndSchedule = const DndSchedule(),
    this.exceptions = const DndExceptions(),
    this.isLoading = false,
  });

  bool get isDndActive {
    if (currentMode == CallHandlingMode.silentDnd) return true;
    if (dndUntil != null && dndUntil!.isAfter(DateTime.now())) return true;

    // Check recurring schedule
    if (dndSchedule.isEnabled) {
      final now = DateTime.now();
      if (dndSchedule.daysOfWeek.contains(now.weekday)) {
        final startMins = dndSchedule.startTime.hour * 60 + dndSchedule.startTime.minute;
        final endMins = dndSchedule.endTime.hour * 60 + dndSchedule.endTime.minute;
        final currentMins = now.hour * 60 + now.minute;
        if (currentMins >= startMins && currentMins < endMins) {
          return true;
        }
      }
    }

    return false;
  }

  String get statusTitle {
    if (!isAssistantActive) return 'Assistant Paused';
    if (isDndActive) {
      if (dndUntil != null && dndUntil!.isAfter(DateTime.now())) {
        final hour = dndUntil!.hour.toString().padLeft(2, '0');
        final min = dndUntil!.minute.toString().padLeft(2, '0');
        return 'DND Active until $hour:$min';
      }
      return 'DND Active (Schedule: ${dndSchedule.label})';
    }
    return '${currentMode.title} Active';
  }

  ModesState copyWith({
    bool? isAssistantActive,
    CallHandlingMode? currentMode,
    DateTime? dndUntil,
    bool clearDndUntil = false,
    DndSchedule? dndSchedule,
    DndExceptions? exceptions,
    bool? isLoading,
  }) {
    return ModesState(
      isAssistantActive: isAssistantActive ?? this.isAssistantActive,
      currentMode: currentMode ?? this.currentMode,
      dndUntil: clearDndUntil ? null : (dndUntil ?? this.dndUntil),
      dndSchedule: dndSchedule ?? this.dndSchedule,
      exceptions: exceptions ?? this.exceptions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final modesControllerProvider =
    StateNotifierProvider<ModesController, ModesState>((ref) {
  return ModesController();
});

class ModesController extends StateNotifier<ModesState> {
  ModesController() : super(const ModesState()) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeId = prefs.getString(AppConstants.keyCallHandlingMode) ??
          CallHandlingMode.serverRelay.id;
      final active = prefs.getBool(AppConstants.keyAssistantActive) ?? true;
      final dndUntilMillis = prefs.getInt(AppConstants.keyDndUntil);
      final allowStarred = prefs.getBool('dnd_allow_starred') ?? true;
      final allowRepeat = prefs.getBool('dnd_allow_repeat_15min') ?? true;
      final whitelist = prefs.getStringList('dnd_whitelist_numbers') ?? [];

      // Load active region emergency numbers
      final selectedCountry = prefs.getString('user_selected_region') ?? AppConfig.defaultRegion;
      final region = AppConfig.supportedRegions.firstWhere(
        (r) => r.countryCode == selectedCountry,
        orElse: () => AppConfig.supportedRegions.first,
      );

      DateTime? until;
      if (dndUntilMillis != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(dndUntilMillis);
        if (dt.isAfter(DateTime.now())) {
          until = dt;
        }
      }

      state = state.copyWith(
        currentMode: CallHandlingMode.fromId(modeId),
        isAssistantActive: active,
        dndUntil: until,
        exceptions: state.exceptions.copyWith(
          allowStarredContacts: allowStarred,
          allowRepeatCallersWithin15Min: allowRepeat,
          emergencyNumbers: region.emergencyNumbers,
          whitelistNumbers: whitelist,
        ),
      );
    } catch (_) {}
  }

  Future<void> toggleAssistant(bool active) async {
    state = state.copyWith(isAssistantActive: active);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyAssistantActive, active);
      await ReliabilityService.setAssistantActive(active);
    } catch (_) {}
  }

  Future<void> setMode(CallHandlingMode mode) async {
    state = state.copyWith(
      currentMode: mode,
      isAssistantActive: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyCallHandlingMode, mode.id);
      await prefs.setBool(AppConstants.keyAssistantActive, true);
      await ReliabilityService.setCallHandlingMode(mode.id);
      await ReliabilityService.setAssistantActive(true);
    } catch (_) {}
  }

  Future<void> startDndForDuration(Duration duration) async {
    final until = DateTime.now().add(duration);
    await startDndUntil(until);
  }

  Future<void> startDndUntil(DateTime until) async {
    state = state.copyWith(
      dndUntil: until,
      isAssistantActive: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.keyDndUntil, until.millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> cancelDnd() async {
    state = state.copyWith(clearDndUntil: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyDndUntil);
    } catch (_) {}
  }

  Future<void> updateSchedule(DndSchedule schedule) async {
    state = state.copyWith(dndSchedule: schedule);
  }

  Future<void> updateExceptions({
    bool? allowStarred,
    bool? allowRepeatCallers,
  }) async {
    final updated = state.exceptions.copyWith(
      allowStarredContacts: allowStarred,
      allowRepeatCallersWithin15Min: allowRepeatCallers,
    );
    state = state.copyWith(exceptions: updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (allowStarred != null) {
        await prefs.setBool('dnd_allow_starred', allowStarred);
      }
      if (allowRepeatCallers != null) {
        await prefs.setBool('dnd_allow_repeat_15min', allowRepeatCallers);
      }
    } catch (_) {}
  }

  Future<void> addWhitelistNumber(String number) async {
    final clean = number.trim();
    if (clean.isEmpty || state.exceptions.whitelistNumbers.contains(clean)) return;

    final updated = [...state.exceptions.whitelistNumbers, clean];
    state = state.copyWith(
      exceptions: state.exceptions.copyWith(whitelistNumbers: updated),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dnd_whitelist_numbers', updated);
    } catch (_) {}
  }

  Future<void> removeWhitelistNumber(String number) async {
    final updated = state.exceptions.whitelistNumbers.where((n) => n != number).toList();
    state = state.copyWith(
      exceptions: state.exceptions.copyWith(whitelistNumbers: updated),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dnd_whitelist_numbers', updated);
    } catch (_) {}
  }
}
