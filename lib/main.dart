import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/app.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/app/config/config_validator.dart';
import 'package:voicemail/app/config/flavor_config.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/logging/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Flavor Configuration (defaulting to dev for mock demo & development)
  FlavorConfig.initialize(
    config: const FlavorConfig(
      flavor: Flavor.dev,
      appTitle: AppConfig.appName,
      applicationId: AppConfig.packageIdDev,
      enableDebugLogging: true,
      mockServicesByDefault: true,
    ),
  );

  // Initialize App Identity and Dynamic Package Information
  await AppConfig.initialize();

  // Run build-time / startup configuration validation
  ConfigValidator.validate();

  bool isOnboardingCompleted = false;

  try {
    final prefs = await SharedPreferences.getInstance();
    isOnboardingCompleted = prefs.getBool(AppConstants.keyOnboardingComplete) ??
        prefs.getBool('onboarding_completed') ??
        false;
  } catch (e) {
    AppLogger.e('Main', 'Preferences initialization error', e);
  }

  // Draw UI immediately to prevent Android splash-screen timeout / ANR
  runApp(
    ProviderScope(
      child: VaniVoicemailApp(isOnboardingCompleted: isOnboardingCompleted),
    ),
  );
}
