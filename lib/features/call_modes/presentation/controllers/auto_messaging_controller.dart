import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/features/call_modes/domain/auto_reply_rules.dart';

class AutoMessagingState {
  final AutoMsgTargetMode targetMode;
  final List<AutoReplyContact> selectedContacts;
  final String customMessage;
  final bool includeWhatsAppLink;
  final String whatsAppNumber;
  final bool emergencyBreakthrough;
  final bool isSaving;

  const AutoMessagingState({
    this.targetMode = AutoMsgTargetMode.all,
    this.selectedContacts = const [],
    this.customMessage = "Hi, Danish here. I can't take your call right now. Please WhatsApp or SMS me. Thanks!",
    this.includeWhatsAppLink = false,
    this.whatsAppNumber = '',
    this.emergencyBreakthrough = true,
    this.isSaving = false,
  });

  String get previewMessage {
    var msg = customMessage.trim();
    if (includeWhatsAppLink && whatsAppNumber.trim().isNotEmpty) {
      final clean = whatsAppNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty) {
        msg += '\n\nChat: https://wa.me/$clean';
      }
    }
    if (emergencyBreakthrough) {
      msg += '\n(If urgent, call back within 3 mins to ring through)';
    }
    return msg;
  }

  AutoMessagingState copyWith({
    AutoMsgTargetMode? targetMode,
    List<AutoReplyContact>? selectedContacts,
    String? customMessage,
    bool? includeWhatsAppLink,
    String? whatsAppNumber,
    bool? emergencyBreakthrough,
    bool? isSaving,
  }) {
    return AutoMessagingState(
      targetMode: targetMode ?? this.targetMode,
      selectedContacts: selectedContacts ?? this.selectedContacts,
      customMessage: customMessage ?? this.customMessage,
      includeWhatsAppLink: includeWhatsAppLink ?? this.includeWhatsAppLink,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
      emergencyBreakthrough: emergencyBreakthrough ?? this.emergencyBreakthrough,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final autoMessagingControllerProvider =
    StateNotifierProvider<AutoMessagingController, AutoMessagingState>((ref) {
  return AutoMessagingController();
});

class AutoMessagingController extends StateNotifier<AutoMessagingState> {
  Future<void>? _initFuture;

  AutoMessagingController() : super(const AutoMessagingState()) {
    _initFuture = loadSettings();
  }

  AutoMessagingState get currentState => state;

  static const String keyTargetMode = 'auto_msg_target_mode';
  static const String keyContacts = 'auto_msg_selected_contacts';
  static const String keyNumbers = 'auto_msg_selected_numbers';
  static const String keyIncludeWa = 'auto_msg_include_whatsapp';
  static const String keyWaNumber = 'auto_msg_whatsapp_number';
  static const String keyDndMsg = 'dnd_msg';
  static const String keyActiveGreeting = 'active_greeting_text';
  static const String keyRepeatAllow = 'dnd_allow_repeat';

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final targetModeStr = prefs.getString(keyTargetMode) ?? 'ALL';
      final targetMode = AutoMsgTargetMode.fromId(targetModeStr);

      final contactsJson = prefs.getString(keyContacts) ?? '[]';
      List<AutoReplyContact> contacts = [];
      try {
        final dynamic rawDecoded = jsonDecode(contactsJson);
        if (rawDecoded is List) {
          contacts = rawDecoded
              .map((e) => AutoReplyContact.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}

      final msg = prefs.getString(keyActiveGreeting) ??
          prefs.getString(keyDndMsg) ??
          "Hi, Danish here. I can't take your call right now. Please WhatsApp or SMS me. Thanks!";

      final includeWa = prefs.getBool(keyIncludeWa) ?? false;
      final waNumber = prefs.getString(keyWaNumber) ?? '';
      final emergency = prefs.getBool(keyRepeatAllow) ?? true;

      state = state.copyWith(
        targetMode: targetMode,
        selectedContacts: contacts,
        customMessage: msg,
        includeWhatsAppLink: includeWa,
        whatsAppNumber: waNumber,
        emergencyBreakthrough: emergency,
      );
    } catch (_) {}
  }

  Future<void> _ensureReady() async {
    if (_initFuture != null) await _initFuture;
  }

  Future<void> setTargetMode(AutoMsgTargetMode mode) async {
    await _ensureReady();
    state = state.copyWith(targetMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTargetMode, mode.id);
  }

  Future<void> addContact(AutoReplyContact contact) async {
    await _ensureReady();
    final existing = List<AutoReplyContact>.from(state.selectedContacts);
    if (!existing.any((c) => c.cleanNumber == contact.cleanNumber)) {
      existing.add(contact);
      state = state.copyWith(selectedContacts: existing);
      await _persistContacts(existing);
    }
  }

  Future<void> removeContact(AutoReplyContact contact) async {
    await _ensureReady();
    final existing = List<AutoReplyContact>.from(state.selectedContacts);
    existing.removeWhere((c) => c.cleanNumber == contact.cleanNumber);
    state = state.copyWith(selectedContacts: existing);
    await _persistContacts(existing);
  }

  Future<void> clearAllContacts() async {
    await _ensureReady();
    state = state.copyWith(selectedContacts: []);
    await _persistContacts([]);
  }

  Future<void> _persistContacts(List<AutoReplyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = jsonEncode(contacts.map((c) => c.toMap()).toList());
    final numbersList = contacts.map((c) => c.cleanNumber).toList();
    final numbersJson = jsonEncode(numbersList);

    await prefs.setString(keyContacts, contactsJson);
    await prefs.setString(keyNumbers, numbersJson);
  }

  Future<void> setCustomMessage(String message) async {
    await _ensureReady();
    state = state.copyWith(customMessage: message);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDndMsg, message);
    await prefs.setString(keyActiveGreeting, message);
  }

  Future<void> toggleIncludeWhatsApp(bool val) async {
    await _ensureReady();
    state = state.copyWith(includeWhatsAppLink: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIncludeWa, val);
  }

  Future<void> setWhatsAppNumber(String number) async {
    await _ensureReady();
    state = state.copyWith(whatsAppNumber: number);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyWaNumber, number);
  }

  Future<void> toggleEmergencyBreakthrough(bool val) async {
    await _ensureReady();
    state = state.copyWith(emergencyBreakthrough: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyRepeatAllow, val);
  }
}
