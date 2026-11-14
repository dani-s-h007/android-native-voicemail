import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voicemail/core/logging/app_logger.dart';
import 'package:voicemail/domain/services/permission_service.dart';

class AppPermissionService implements PermissionService {
  static const MethodChannel _dndChannel =
      MethodChannel('com.dalsc.voicemail_assistant/dnd');
  static const MethodChannel _reliabilityChannel =
      MethodChannel('com.dalsc.voicemail_assistant/reliability');

  @override
  Future<bool> isPhonePermissionGranted() async {
    try {
      return await Permission.phone.isGranted;
    } catch (e) {
      AppLogger.w('Permission', 'Error checking phone permission: $e');
      return true; // Fallback for desktop/simulator demo
    }
  }

  @override
  Future<bool> isContactsPermissionGranted() async {
    try {
      return await Permission.contacts.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> isMicrophonePermissionGranted() async {
    try {
      return await Permission.microphone.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> isNotificationsPermissionGranted() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> isCallScreeningRoleHeld() async {
    try {
      final held =
          await _dndChannel.invokeMethod<bool>('isCallScreeningRoleHeld');
      return held ?? false;
    } catch (e) {
      return true; // Fallback for simulator
    }
  }

  @override
  Future<bool> isBatteryOptimizationExempt() async {
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> requestPhonePermission() async {
    try {
      final status = await Permission.phone.request();
      return status.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> requestContactsPermission() async {
    try {
      final status = await Permission.contacts.request();
      return status.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> requestNotificationsPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> requestCallScreeningRole() async {
    try {
      final success =
          await _dndChannel.invokeMethod<bool>('requestCallScreeningRole');
      return success ?? false;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> requestBatteryOptimizationExempt() async {
    try {
      await _reliabilityChannel.invokeMethod('requestIgnoreBatteryOptimizations');
      return true;
    } catch (e) {
      try {
        final status = await Permission.ignoreBatteryOptimizations.request();
        return status.isGranted;
      } catch (_) {
        return true;
      }
    }
  }

  @override
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'phone': await isPhonePermissionGranted(),
      'contacts': await isContactsPermissionGranted(),
      'microphone': await isMicrophonePermissionGranted(),
      'notifications': await isNotificationsPermissionGranted(),
      'callScreening': await isCallScreeningRoleHeld(),
      'batteryExempt': await isBatteryOptimizationExempt(),
    };
  }
}

