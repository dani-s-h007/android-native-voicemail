import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        final timeStr = TimeOfDay.fromDateTime(dndUntil!).format;
        return 'DND Active until ${dndUntil!.hour}:${dndUntil!.minute.toString().padLeft(2, '0')}';
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
      );
    } catch (_) {}
  }

  Future<void> toggleAssistant(bool active) async {
    state = state.copyWith(isAssistantActive: active);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAssistantActive, active);
    await ReliabilityService.setAssistantActive(active);
  }

  Future<void> setMode(CallHandlingMode mode) async {
    state = state.copyWith(
      currentMode: mode,
      isAssistantActive: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCallHandlingMode, mode.id);
    await prefs.setBool(AppConstants.keyAssistantActive, true);
    await ReliabilityService.setCallHandlingMode(mode.id);
    await ReliabilityService.setAssistantActive(true);
  }

  Future<void> startDndForDuration(Duration duration) async {
    final until = DateTime.now().add(duration);
    state = state.copyWith(
      dndUntil: until,
      isAssistantActive: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyDndUntil, until.millisecondsSinceEpoch);
  }

  Future<void> cancelDnd() async {
    state = state.copyWith(clearDndUntil: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyDndUntil);
  }

  Future<void> updateSchedule(DndSchedule schedule) async {
    state = state.copyWith(dndSchedule: schedule);
  }

  Future<void> updateExceptions({
    bool? allowStarred,
    bool? allowRepeatCallers,
  }) async {
    state = state.copyWith(
      exceptions: state.exceptions.copyWith(
        allowStarredContacts: allowStarred,
        allowRepeatCallers: allowRepeatCallers,
      ),
    );
  }
}

