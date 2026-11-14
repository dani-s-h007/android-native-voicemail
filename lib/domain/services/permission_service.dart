abstract class PermissionService {
  Future<bool> isPhonePermissionGranted();
  Future<bool> isContactsPermissionGranted();
  Future<bool> isMicrophonePermissionGranted();
  Future<bool> isNotificationsPermissionGranted();
  Future<bool> isCallScreeningRoleHeld();
  Future<bool> isBatteryOptimizationExempt();

  Future<bool> requestPhonePermission();
  Future<bool> requestContactsPermission();
  Future<bool> requestMicrophonePermission();
  Future<bool> requestNotificationsPermission();
  Future<bool> requestCallScreeningRole();
  Future<bool> requestBatteryOptimizationExempt();

  Future<Map<String, bool>> checkAllPermissions();
}

