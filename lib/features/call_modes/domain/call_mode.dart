import 'package:flutter/material.dart';

enum CallHandlingMode {
  serverRelay(
    id: 'MODE_1_SERVER_RELAY',
    title: 'Standard Server Greeting',
    subtitle: 'Carrier forwards busy or unanswered calls to voicemail relay',
    costDescription: 'Standard carrier rates',
    icon: Icons.cloud_outlined,
    badgeText: 'CARRIER RELAY',
  ),
  autoDecline(
    id: 'MODE_2_AUTO_DECLINE',
    title: 'Auto-Decline with Message',
    subtitle: 'Screen calls silently and dispatch instant SMS or messaging link',
    costDescription: 'Standard SMS rates apply • Local processing',
    icon: Icons.phone_disabled_outlined,
    badgeText: 'LOCAL SCREENING',
  ),
  autoAnswer(
    id: 'MODE_3_AUTO_ANSWER',
    title: 'Auto-Answer Assistant',
    subtitle: 'Answers locally on device, speaks greeting, and transcribes speech',
    costDescription: 'On-device assistant • Local processing',
    icon: Icons.voicemail_rounded,
    badgeText: 'ON-DEVICE',
  ),
  silentDnd(
    id: 'MODE_4_SILENT_DND',
    title: 'Silent DND Mode',
    subtitle: 'Total silence during meetings, focus, and quiet hours',
    costDescription: 'Local device management',
    icon: Icons.do_not_disturb_on_outlined,
    badgeText: 'DO NOT DISTURB',
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
    this.endTime = const TimeOfDay(hour: 17, minute: 0),
    this.daysOfWeek = const [1, 2, 3, 4, 5], // Mon - Fri
    this.label = 'Work & Focus Hours',
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
  final bool allowRepeatCallersWithin15Min;
  final List<String> emergencyNumbers;
  final List<String> whitelistNumbers;

  const DndExceptions({
    this.allowStarredContacts = true,
    this.allowRepeatCallersWithin15Min = true,
    this.emergencyNumbers = const ['911', '112', '999', '100', '108', '101'],
    this.whitelistNumbers = const [],
  });

  DndExceptions copyWith({
    bool? allowStarredContacts,
    bool? allowRepeatCallersWithin15Min,
    List<String>? emergencyNumbers,
    List<String>? whitelistNumbers,
  }) {
    return DndExceptions(
      allowStarredContacts: allowStarredContacts ?? this.allowStarredContacts,
      allowRepeatCallersWithin15Min:
          allowRepeatCallersWithin15Min ?? this.allowRepeatCallersWithin15Min,
      emergencyNumbers: emergencyNumbers ?? this.emergencyNumbers,
      whitelistNumbers: whitelistNumbers ?? this.whitelistNumbers,
    );
  }
}
