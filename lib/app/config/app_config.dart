import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  /// Easily rebrand the application from here
  static const String appName = 'Vani Voicemail';
  static const String appTagline = 'Smart On-Device Voicemail & Call Assistant';

  /// Creator & Portfolio
  static const String developerName = 'Danish K';
  static const String developerWebsite = 'https://danishk.web.app';
  static const String supportEmail = 'support@danishk.web.app';

  /// Telephony & Storage defaults
  static const String defaultCarrierForwardingNumber = '+914954268791';
  static const String databaseName = 'vani_voicemail_local.db';

  /// Dynamic Package Information
  static late final String version;
  static late final String buildNumber;
  static late final String packageName;

  static Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version.isNotEmpty ? info.version : '1.0.0';
      buildNumber = info.buildNumber.isNotEmpty ? info.buildNumber : '1';
      packageName = info.packageName.isNotEmpty ? info.packageName : 'com.dalsc.voicemail_assistant';
    } catch (_) {
      version = '1.0.0';
      buildNumber = '1';
      packageName = 'com.dalsc.voicemail_assistant';
    }
  }
}

