abstract class AppConstants {
  // Shared Preferences Keys
  static const String keyCallHandlingMode = 'call_handling_mode';
  static const String keyAssistantActive = 'assistant_active';
  static const String keyForwardingActive = 'forwarding_active';
  static const String keyForwardingRelayNumber = 'forwarding_relay_number';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyConsentAccepted = 'consent_accepted';
  static const String keySelectedThemeMode = 'selected_theme_mode';
  static const String keyUseDynamicColor = 'use_dynamic_color';
  static const String keySelectedLanguage = 'selected_language';
  static const String keyBlockScreenCapture = 'block_screen_capture';
  static const String keyDndActive = 'dnd_active';
  static const String keyDndUntil = 'dnd_until';
  static const String keyUserDisplayName = 'user_display_name';
  static const String keyUserPhoneNumber = 'user_phone_number';
  static const String keyUserSecondaryNumber = 'user_secondary_number';
  static const String keySelectedRegion = 'selected_region';
  static const String keySelectedCarrier = 'selected_carrier';
  static const String keyCustomCarrier = 'custom_carrier';
  static const String keyNotificationSound = 'notification_sound';
  static const String keyVibrateOnVoicemail = 'vibrate_on_voicemail';
  static const String keyPriorityAlerts = 'priority_alerts';
  static const String keyBackupLocation = 'backup_location';

  // Modes
  static const String modeServerRelay = 'MODE_1_SERVER_RELAY';
  static const String modeAutoDecline = 'MODE_2_AUTO_DECLINE';
  static const String modeAutoAnswer = 'MODE_3_AUTO_ANSWER';
  static const String modeSilentDnd = 'MODE_4_SILENT_DND';

  // Default Carrier / Voicemail Relay Number
  static const String defaultVoicemailRelayNumber = '+15550198765';
  static const String defaultExotelKeralaDid = '+15550198765';

  // Routes
  static const String routeSplash = '/splash';
  static const String routeOnboarding = '/onboarding';
  static const String routeConsent = '/consent';
  static const String routePermissions = '/permissions';
  static const String routeSetupWizard = '/setup-wizard';
  static const String routeHome = '/';
  static const String routeVoicemail = '/voicemail';
  static const String routeVoicemailDetail = '/voicemail/:id';
  static const String routeModes = '/modes';
  static const String routeGreetings = '/greetings';
  static const String routeSettings = '/settings';
  static const String routeReliability = '/reliability';
  static const String routeDiagnostics = '/diagnostics';
  static const String routeRegionCarrier = '/region-carrier';
  static const String routeAbout = '/about';
  static const String routeFeedback = '/feedback';
  static const String routeLegal = '/legal/:document';
  static const String routeComponentGallery = '/component-gallery';
}

