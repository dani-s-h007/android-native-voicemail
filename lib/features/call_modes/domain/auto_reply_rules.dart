import 'dart:convert';
import 'package:flutter/material.dart';

enum AutoMsgTargetMode {
  all(
    id: 'ALL',
    title: 'All Callers',
    subtitle: 'Auto-reply to every incoming call that gets declined',
    icon: Icons.people_outline_rounded,
    badgeText: 'EVERYONE',
  ),
  selectedOnly(
    id: 'SELECTED_ONLY',
    title: 'Selected Numbers Only',
    subtitle: 'Only auto-reply to specific whitelisted contacts / numbers',
    icon: Icons.playlist_add_check_rounded,
    badgeText: 'WHITELIST',
  ),
  unsavedOnly(
    id: 'UNSAVED_ONLY',
    title: 'Unsaved / Unknown Numbers Only',
    subtitle: 'Screen unknown callers without texting your saved contacts',
    icon: Icons.person_add_disabled_outlined,
    badgeText: 'UNKNOWN ONLY',
  ),
  excludeSelected(
    id: 'EXCLUDE_SELECTED',
    title: 'Exclude Selected Numbers',
    subtitle: 'Auto-reply to everyone except specific blacklisted numbers',
    icon: Icons.block_flipped,
    badgeText: 'BLACKLIST',
  );

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;

  const AutoMsgTargetMode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
  });

  static AutoMsgTargetMode fromId(String id) {
    return AutoMsgTargetMode.values.firstWhere(
      (m) => m.id == id,
      orElse: () => AutoMsgTargetMode.all,
    );
  }
}

class AutoReplyContact {
  final String name;
  final String number;

  const AutoReplyContact({
    required this.name,
    required this.number,
  });

  String get cleanNumber {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'number': number,
      };

  factory AutoReplyContact.fromMap(Map<String, dynamic> map) => AutoReplyContact(
        name: (map['name'] as String?) ?? 'Unknown',
        number: (map['number'] as String?) ?? '',
      );

  String toJson() => jsonEncode(toMap());
  factory AutoReplyContact.fromJson(String source) =>
      AutoReplyContact.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoReplyContact &&
          runtimeType == other.runtimeType &&
          cleanNumber == other.cleanNumber;

  @override
  int get hashCode => cleanNumber.hashCode;
}

class AutoReplyPreset {
  final String title;
  final String iconEmoji;
  final String template;

  const AutoReplyPreset({
    required this.title,
    required this.iconEmoji,
    required this.template,
  });

  static const List<AutoReplyPreset> presets = [
    AutoReplyPreset(
      title: 'General',
      iconEmoji: '💬',
      template: "Hi, Danish here. I can't take your call right now. Please WhatsApp or SMS me. Thanks!",
    ),
    AutoReplyPreset(
      title: 'In Class / College',
      iconEmoji: '🎓',
      template: "Hi, Danish here. I'm currently attending class/lecture and cannot take calls. Please message me.",
    ),
    AutoReplyPreset(
      title: 'Driving',
      iconEmoji: '🚗',
      template: "Hi, I'm driving right now and can't answer safely. I'll get back to you once parked.",
    ),
    AutoReplyPreset(
      title: 'In a Meeting',
      iconEmoji: '💼',
      template: "Hi, I'm in an important meeting. Please text me the details or reach out on WhatsApp.",
    ),
    AutoReplyPreset(
      title: 'Do Not Disturb',
      iconEmoji: '😴',
      template: "Hi, I'm currently unavailable on DND. Please drop a message and I'll reply soon.",
    ),
  ];
}
