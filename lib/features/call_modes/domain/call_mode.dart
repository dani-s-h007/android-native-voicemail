import 'package:flutter/material.dart';

enum CallHandlingMode {
  serverRelay(
    id: 'MODE_1_SERVER_RELAY',
    title: 'Server Greeting Mode',
    subtitle: 'Carrier forwards busy/declined calls to Kerala DID',
    costDescription: 'Minimal 1 pulse (~₹0.30)',
    icon: Icons.cloud_outlined,
    badgeText: 'RECOMMENDED',
  ),
  autoDecline(
    id: 'MODE_2_AUTO_DECLINE',
    title: 'Auto-Decline with Message',
    subtitle: 'Silently rejects unsaved callers and prompts SMS/WhatsApp',
    costDescription: '100% Free (₹0 credits)',
    icon: Icons.phone_disabled_outlined,
    badgeText: 'LOCAL SCREENING',
  ),
  autoAnswer(
    id: 'MODE_3_AUTO_ANSWER',
    title: 'Live Voicemail (iPhone Style)',
    subtitle: 'Answers locally on device, plays greeting, and records caller for ₹0',
    costDescription: '100% Free (No Carrier Setup / ₹0)',
    icon: Icons.voicemail_rounded,
    badgeText: 'IPHONE STYLE',
  ),
  silentDnd(
    id: 'MODE_4_SILENT_DND',
    title: 'Silent DND Mode',
    subtitle: 'Total silence during classes, lectures, and exams',
    costDescription: '100% Free (₹0 credits)',
    icon: Icons.do_not_disturb_on_outlined,
    badgeText: 'ZERO DISTRACTION',
  );

  final String id;
  final String title;
  final String subtitle;
  final String costDescription;
  final IconData icon;
  final String badgeText;

  const CallHandlingMode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.costDescription,
    required this.icon,
    required this.badgeText,
  });

  static CallHandlingMode fromId(String id) {
    return CallHandlingMode.values.firstWhere(
      (m) => m.id == id,
      orElse: () => CallHandlingMode.serverRelay,
    );
  }
}

class DndSchedule {
  final bool isEnabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final String label;

  const DndSchedule({
    this.isEnabled = false,
    this.startTime = const TimeOfDay(hour: 9, minute: 0),
    this.endTime = const TimeOfDay(hour: 16, minute: 0),
    this.daysOfWeek = const [1, 2, 3, 4, 5], // Mon - Fri (College/Class)
    this.label = 'College / Class Schedule',
  });

  DndSchedule copyWith({
    bool? isEnabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? daysOfWeek,
    String? label,
  }) {
    return DndSchedule(
      isEnabled: isEnabled ?? this.isEnabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      label: label ?? this.label,
    );
  }
}

class DndExceptions {
  final bool allowStarredContacts;
  final bool allowRepeatCallers; // 2nd call within 3 minutes
  final List<String> emergencyNumbers; // 112, 100, 108

  const DndExceptions({
    this.allowStarredContacts = true,
    this.allowRepeatCallers = true,
    this.emergencyNumbers = const ['112', '100', '108', '101'],
  });

  DndExceptions copyWith({
    bool? allowStarredContacts,
    bool? allowRepeatCallers,
  }) {
    return DndExceptions(
      allowStarredContacts: allowStarredContacts ?? this.allowStarredContacts,
      allowRepeatCallers: allowRepeatCallers ?? this.allowRepeatCallers,
      emergencyNumbers: emergencyNumbers,
    );
  }
}

