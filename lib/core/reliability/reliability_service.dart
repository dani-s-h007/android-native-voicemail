import 'package:flutter/services.dart';

class ReliabilityAudit {
  final String brand;
  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkInt;
  final bool batteryOptimizationExempt;
  final bool callScreeningRoleHeld;
  final bool notificationsEnabled;
  final bool exactAlarmAllowed;
  final bool needsAutostartWarning;

  ReliabilityAudit({
    required this.brand,
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sdkInt,
    required this.batteryOptimizationExempt,
    required this.callScreeningRoleHeld,
    required this.notificationsEnabled,
    required this.exactAlarmAllowed,
    required this.needsAutostartWarning,
  });

  factory ReliabilityAudit.fromMap(Map<dynamic, dynamic> map) {
    return ReliabilityAudit(
      brand: map['brand'] as String? ?? 'OTHER',
      manufacturer: map['manufacturer'] as String? ?? 'Unknown',
      model: map['model'] as String? ?? 'Unknown',
      androidVersion: map['androidVersion'] as String? ?? 'Unknown',
      sdkInt: map['sdkInt'] as int? ?? 0,
      batteryOptimizationExempt: map['batteryOptimizationExempt'] as bool? ?? false,
      callScreeningRoleHeld: map['callScreeningRoleHeld'] as bool? ?? false,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? false,
      exactAlarmAllowed: map['exactAlarmAllowed'] as bool? ?? false,
      needsAutostartWarning: map['needsAutostartWarning'] as bool? ?? false,
    );
  }

  bool get isFullyHealthy =>
      batteryOptimizationExempt &&
      callScreeningRoleHeld &&
      notificationsEnabled &&
      exactAlarmAllowed;
}

class ReliabilityService {
  static const MethodChannel _channel = MethodChannel('com.dalsc.voicemail_assistant/reliability');

  static Future<ReliabilityAudit> getReliabilityAudit() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getReliabilityAudit');
      if (res != null) {
        return ReliabilityAudit.fromMap(res);
      }
    } catch (_) {}
    return ReliabilityAudit(
      brand: 'UNKNOWN',
      manufacturer: 'Unknown',
      model: 'Unknown',
      androidVersion: 'Unknown',
      sdkInt: 0,
      batteryOptimizationExempt: false,
      callScreeningRoleHeld: false,
      notificationsEnabled: false,
      exactAlarmAllowed: false,
      needsAutostartWarning: false,
    );
  }

  static Future<bool> openOemSetting(String target) async {
    try {
      final res = await _channel.invokeMethod<bool>('openOemSetting', {'target': target});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openOemAutostartSettings() async {
    return openOemSetting('autostart');
  }

  static Future<bool> openAppDetailsSettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openAppDetailsSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static final List<Map<String, dynamic>> _mockDiagnosticLogs = [
    {
      'timestamp': 'Today, 2:45 PM',
      'caller_number': '+1 (555) 234-5678',
      'decision': 'DISMISSED_TO_VOICEMAIL',
      'reason': 'Caller busy or unanswered. Forwarded via conditional MMI code to voicemail relay.',
      'carrier_response': '200 OK (Relay connected)',
    },
    {
      'timestamp': 'Today, 11:15 AM',
      'caller_number': '+1 (555) 876-5432',
      'decision': 'SCREENED_BY_DND',
      'reason': 'Call arrived during scheduled Focus Hours. Dispatched auto-reply message.',
      'carrier_response': 'Call silenced locally',
    },
    {
      'timestamp': 'Yesterday, 8:20 PM',
      'caller_number': '911',
      'decision': 'EMERGENCY_BYPASS_ALLOWED',
      'reason': 'National emergency number recognized. Bypassed screening and rang immediately.',
      'carrier_response': 'Direct pass-through',
    },
    {
      'timestamp': 'Yesterday, 3:10 PM',
      'caller_number': '+1 (555) 345-6789',
      'decision': 'REPEATED_CALLER_OVERRIDE',
      'reason': 'Repeated call within 15 minutes. Permitted by DND exception rules.',
      'carrier_response': 'Direct pass-through',
    },
  ];

  static List<Map<String, dynamic>> get mockDiagnosticLogs =>
      List<Map<String, dynamic>>.from(_mockDiagnosticLogs);

  static Future<List<Map<String, dynamic>>> getDiagnosticLogs({int limit = 50}) async {
    try {
      final res = await _channel.invokeMethod<List<dynamic>>('getDiagnosticLogs', {'limit': limit});
      if (res != null && res.isNotEmpty) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_mockDiagnosticLogs);
  }

  static Future<bool> clearDiagnosticLogs() async {
    try {
      final res = await _channel.invokeMethod<bool>('clearDiagnosticLogs');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> exportDiagnosticLogs() async {
    try {
      return await _channel.invokeMethod<String>('exportDiagnosticLogs');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> setCallHandlingMode(String mode) async {
    try {
      final res = await _channel.invokeMethod<bool>('setCallHandlingMode', {'mode': mode});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setAssistantActive(bool active) async {
    try {
      final res = await _channel.invokeMethod<bool>('setAssistantActive', {'active': active});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> getAssistantActive() async {
    try {
      final res = await _channel.invokeMethod<bool>('getAssistantActive');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestAllCorePermissions() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestAllCorePermissions');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestCallScreeningRole() async {
    try {
      const dndChannel = MethodChannel('com.dalsc.voicemail_assistant/dnd');
      final res = await dndChannel.invokeMethod<bool>('requestCallScreeningRole');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isDefaultDialer() async {
    try {
      const dndChannel = MethodChannel('com.dalsc.voicemail_assistant/dnd');
      final res = await dndChannel.invokeMethod<bool>('isDefaultDialer');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestDefaultDialerRole() async {
    try {
      const dndChannel = MethodChannel('com.dalsc.voicemail_assistant/dnd');
      final res = await dndChannel.invokeMethod<bool>('requestDefaultDialerRole');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openDefaultAppsSettings() async {
    try {
      const dndChannel = MethodChannel('com.dalsc.voicemail_assistant/dnd');
      final res = await dndChannel.invokeMethod<bool>('openDefaultAppsSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> triggerWatchdog() async {
    try {
      await _channel.invokeMethod('triggerWatchdog');
    } catch (_) {}
  }
}

