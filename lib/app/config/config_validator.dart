import 'package:flutter/foundation.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/app/config/flavor_config.dart';

/// Validates that no `TODO_UPDATE` placeholder values remain in production.
///
/// In the `prod` flavor, any unconfigured field will throw a [ConfigValidationException]
/// and halt execution or build. In `dev` or `staging`, warnings are emitted without halting.
class ConfigValidator {
  const ConfigValidator._();

  static const String placeholderMarker = 'TODO_UPDATE';
  static const String exampleDomainMarker = 'example.com';

  /// Validates [AppConfig] against the active [Flavor].
  /// Returns a list of validation violation messages.
  static List<String> findViolations({Flavor flavor = Flavor.prod}) {
    final violations = <String>[];

    void checkField(String fieldName, String value, {bool checkExampleDomain = true}) {
      if (value.contains(placeholderMarker)) {
        violations.add("Field '$fieldName' contains unconfigured placeholder '$value'.");
      }
      if (checkExampleDomain && value.contains(exampleDomainMarker)) {
        violations.add("Field '$fieldName' points to dummy placeholder domain '$value'.");
      }
    }

    checkField('developerName', AppConfig.developerName, checkExampleDomain: false);
    checkField('developerWebsiteUrl', AppConfig.developerWebsiteUrl);
    checkField('supportEmail', AppConfig.supportEmail);
    checkField('privacyPolicyUrl', AppConfig.privacyPolicyUrl);
    checkField('termsUrl', AppConfig.termsUrl);
    checkField('dataSafetyUrl', AppConfig.dataSafetyUrl);
    checkField('recordingNoticeUrl', AppConfig.recordingNoticeUrl);
    checkField('companyLegalName', AppConfig.companyLegalName, checkExampleDomain: false);
    checkField('companyAddress', AppConfig.companyAddress, checkExampleDomain: false);
    checkField('packageIdProd', AppConfig.packageIdProd, checkExampleDomain: false);

    if (AppConfig.enableGrievanceOfficer) {
      checkField('grievanceOfficerName', AppConfig.grievanceOfficerName, checkExampleDomain: false);
      checkField('grievanceOfficerContact', AppConfig.grievanceOfficerContact, checkExampleDomain: false);
    }

    return violations;
  }

  /// Runs validation. Throws [ConfigValidationException] if in [Flavor.prod] and violations exist.
  static void validate({Flavor? flavor}) {
    final activeFlavor = flavor ??
        (FlavorConfig.isInitialized ? FlavorConfig.instance.flavor : Flavor.dev);

    final violations = findViolations(flavor: activeFlavor);

    if (violations.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln('\n======================================================');
      buffer.writeln(' CONFIGURATION VALIDATION FAILED FOR FLAVOR: ${activeFlavor.name.toUpperCase()}');
      buffer.writeln('======================================================');
      buffer.writeln('The following fields must be updated before production:');
      for (final v in violations) {
        buffer.writeln(' - $v');
      }
      buffer.writeln('\nRefer to docs/UPDATE_CHECKLIST.md for update instructions.');
      buffer.writeln('======================================================\n');

      if (activeFlavor == Flavor.prod) {
        throw ConfigValidationException(buffer.toString(), violations);
      } else {
        // In dev or staging, log warning but do not crash
        debugPrint(buffer.toString());
      }
    }
  }
}

class ConfigValidationException implements Exception {
  final String message;
  final List<String> violations;

  const ConfigValidationException(this.message, this.violations);

  @override
  String toString() => message;
}

