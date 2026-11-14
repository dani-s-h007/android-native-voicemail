import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/core/reliability/reliability_service.dart';

void main() {
  group('Reliability & Health Audit Unit Tests', () {
    test('ReliabilityAudit correctly identifies healthy state', () {
      final audit = ReliabilityAudit(
        brand: 'GOOGLE',
        manufacturer: 'Google',
        model: 'Pixel 8',
        androidVersion: '14',
        sdkInt: 34,
        batteryOptimizationExempt: true,
        callScreeningRoleHeld: true,
        notificationsEnabled: true,
        exactAlarmAllowed: true,
        needsAutostartWarning: false,
      );

      expect(audit.isFullyHealthy, isTrue);
    });

    test('ReliabilityAudit marks unhealthy when role is missing', () {
      final audit = ReliabilityAudit(
        brand: 'XIAOMI',
        manufacturer: 'Xiaomi',
        model: 'Redmi Note 13',
        androidVersion: '14',
        sdkInt: 34,
        batteryOptimizationExempt: true,
        callScreeningRoleHeld: false, // Revoked
        notificationsEnabled: true,
        exactAlarmAllowed: true,
        needsAutostartWarning: true,
      );

      expect(audit.isFullyHealthy, isFalse);
    });

    test('ReliabilityAudit deserializes from native map safely', () {
      final nativeMap = {
        'brand': 'SAMSUNG',
        'manufacturer': 'Samsung',
        'model': 'Galaxy S23',
        'androidVersion': '14',
        'sdkInt': 34,
        'batteryOptimizationExempt': true,
        'callScreeningRoleHeld': true,
        'notificationsEnabled': true,
        'exactAlarmAllowed': false,
        'needsAutostartWarning': false,
      };

      final audit = ReliabilityAudit.fromMap(nativeMap);
      expect(audit.brand, 'SAMSUNG');
      expect(audit.model, 'Galaxy S23');
      expect(audit.isFullyHealthy, isFalse); // exactAlarmAllowed is false
    });
  });
}

