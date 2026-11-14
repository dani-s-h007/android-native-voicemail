import 'package:voicemail/domain/services/permission_service.dart';

/// Fake in-memory mock permission service for standalone preview, tests, and demo mode.
class FakePermissionService implements PermissionService {
  final Map<String, bool> _statuses;

  FakePermissionService({Map<String, bool>? initialStatuses})
      : _statuses = initialStatuses ??
            {
              'callScreening': false,
              'phone': false,
              'microphone': false,
              'contacts': false,
              'batteryExempt': false,
              'notifications': false,
            };

  @override
  Future<bool> isPhonePermissionGranted() async => _statuses['phone'] ?? false;

  @override
  Future<bool> isContactsPermissionGranted() async =>
      _statuses['contacts'] ?? false;

  @override
  Future<bool> isMicrophonePermissionGranted() async =>
      _statuses['microphone'] ?? false;

  @override
  Future<bool> isNotificationsPermissionGranted() async =>
      _statuses['notifications'] ?? false;

  @override
  Future<bool> isCallScreeningRoleHeld() async =>
      _statuses['callScreening'] ?? false;

  @override
  Future<bool> isBatteryOptimizationExempt() async =>
      _statuses['batteryExempt'] ?? false;

  @override
  Future<bool> requestPhonePermission() async {
    _statuses['phone'] = true;
    return true;
  }

  @override
  Future<bool> requestContactsPermission() async {
    _statuses['contacts'] = true;
    return true;
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    _statuses['microphone'] = true;
    return true;
  }

  @override
  Future<bool> requestNotificationsPermission() async {
    _statuses['notifications'] = true;
    return true;
  }

  @override
  Future<bool> requestCallScreeningRole() async {
    _statuses['callScreening'] = true;
    return true;
  }

  @override
  Future<bool> requestBatteryOptimizationExempt() async {
    _statuses['batteryExempt'] = true;
    return true;
  }

  @override
  Future<Map<String, bool>> checkAllPermissions() async {
    return Map<String, bool>.from(_statuses);
  }
}
