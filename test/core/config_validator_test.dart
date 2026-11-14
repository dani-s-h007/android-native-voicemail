import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/app/config/config_validator.dart';
import 'package:voicemail/app/config/flavor_config.dart';

void main() {
  group('AppConfig & Placeholder Tests', () {
    test('AppConfig exposes valid identity, branding, and defaults', () {
      expect(AppConfig.appName, isNotEmpty);
      expect(AppConfig.appTagline, isNotEmpty);
      expect(AppConfig.defaultRegion, isNotEmpty);
      expect(AppConfig.supportedRegions, isNotEmpty);
      expect(AppConfig.defaultCarrierProfiles, isNotEmpty);
      expect(AppConfig.supportedLanguages, isNotEmpty);
      expect(AppConfig.brandSeedColor, isNotNull);
    });

    test('Supported regions contain valid emergency numbers and consent rules', () {
      final us = AppConfig.supportedRegions.firstWhere((r) => r.countryCode == 'US');
      expect(us.emergencyNumbers, contains('911'));
      expect(us.recordingConsentNotice, isNotEmpty);
      expect(us.applicablePrivacyLaw, isNotEmpty);

      final gb = AppConfig.supportedRegions.firstWhere((r) => r.countryCode == 'GB');
      expect(gb.emergencyNumbers, contains('999'));
    });

    test('Carrier profiles contain unverified disclaimer and essential MMI codes', () {
      for (final profile in AppConfig.defaultCarrierProfiles) {
        expect(profile.forwardBusyCode, isNotEmpty);
        expect(profile.cancelAllCode, isNotEmpty);
        expect(profile.notes, isNotEmpty);
      }
    });
  });

  group('ConfigValidator Unit Tests', () {
    test('findViolations detects TODO_UPDATE and placeholder domains for production', () {
      final violations = ConfigValidator.findViolations(flavor: Flavor.prod);
      expect(violations, isNotEmpty);

      final hasPlaceholder = violations.any((v) => v.contains('TODO_UPDATE'));
      final hasDomain = violations.any((v) => v.contains('example.com'));

      expect(hasPlaceholder, isTrue, reason: 'Must detect TODO_UPDATE markers');
      expect(hasDomain, isTrue, reason: 'Must detect example.com dummy URLs');
    });

    test('validate throws ConfigValidationException in prod when placeholders remain', () {
      expect(
        () => ConfigValidator.validate(flavor: Flavor.prod),
        throwsA(isA<ConfigValidationException>()),
      );
    });

    test('validate does not throw in dev mode, allowing continuous local development', () {
      expect(
        () => ConfigValidator.validate(flavor: Flavor.dev),
        returnsNormally,
      );
    });
  });
}
