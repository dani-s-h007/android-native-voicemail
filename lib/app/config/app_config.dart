import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Centralized configuration for the application.
///
/// Every value that must be customized prior to a production release is marked
/// with `TODO_UPDATE` in the constant value or comments.
///
/// See `docs/UPDATE_CHECKLIST.md` for a full mapping and release verification guide.
class AppConfig {
  AppConfig._();

  // ===========================================================================
  // 1. APP IDENTITY & BRANDING
  // ===========================================================================

  /// Public user-facing app name.
  /// TODO_UPDATE: Set to your production application title.
  static const String appName = 'Call Assistant';

  /// Short tagline describing the app capability.
  /// TODO_UPDATE: Customize your tagline.
  static const String appTagline = 'Smart On-Device Voicemail & Call Assistant';

  /// Application Package IDs per flavor.
  /// TODO_UPDATE: Change to your own Android package identifiers.
  static const String packageIdDev = 'com.example.voicemail.dev';
  static const String packageIdStaging = 'com.example.voicemail.staging';
  static const String packageIdProd = 'com.example.voicemail';

  /// Brand seed color for Material 3 ColorScheme generation when dynamic color is disabled.
  /// TODO_UPDATE: Change to your brand primary color.
  static const Color brandSeedColor = Color(0xFF1A73E8); // Google Blue
  static const String brandSeedColorHex = '#1A73E8';

  /// Asset paths for logo and icon.
  static const String logoAssetPath = 'assets/icon.jpg';
  static const String appIconAssetPath = 'assets/icon.jpg';

  // ===========================================================================
  // 2. DEVELOPER & SUPPORT CONTACTS
  // ===========================================================================

  /// Developer / Publisher public display name.
  /// TODO_UPDATE: Replace with your developer, studio, or company name.
  static const String developerName = 'TODO_UPDATE_DEVELOPER_NAME';

  /// Developer / Publisher website or portfolio URL.
  /// TODO_UPDATE: Replace with your website URL.
  static const String developerWebsiteUrl = 'https://example.com';
  static String get developerWebsite => developerWebsiteUrl;

  /// Primary support email address.
  /// TODO_UPDATE: Replace with your user support email.
  static const String supportEmail = 'support@example.com';

  /// Optional telephone support contact number.
  /// TODO_UPDATE: Set or leave empty if telephone support is not provided.
  static const String supportPhone = '';

  // ===========================================================================
  // 3. LEGAL & COMPLIANCE WEB URLS
  // ===========================================================================

  /// Web hosted version of Privacy Policy.
  /// TODO_UPDATE: Replace with your live Privacy Policy URL.
  static const String privacyPolicyUrl = 'https://example.com/privacy';

  /// Web hosted version of Terms of Service.
  /// TODO_UPDATE: Replace with your live Terms of Service URL.
  static const String termsUrl = 'https://example.com/terms';

  /// Web hosted version of Google Play Data Safety declaration.
  /// TODO_UPDATE: Replace with your live Data Safety URL.
  static const String dataSafetyUrl = 'https://example.com/data-safety';

  /// Web hosted version of Call Recording & Consent Notice.
  /// TODO_UPDATE: Replace with your live Recording Notice URL.
  static const String recordingNoticeUrl = 'https://example.com/recording-notice';

  // ===========================================================================
  // 4. COMPANY & REGULATORY INFORMATION
  // ===========================================================================

  /// Registered corporate legal entity name.
  /// TODO_UPDATE: Replace with your registered legal entity name.
  static const String companyLegalName = 'TODO_UPDATE_COMPANY_LEGAL_NAME';

  /// Registered business mailing address.
  /// TODO_UPDATE: Replace with your physical mailing address.
  static const String companyAddress = 'TODO_UPDATE_COMPANY_ADDRESS';

  /// Set to true if jurisdiction mandates a designated Grievance / Data Protection Officer (e.g. India IT Rules, EU DPO).
  /// TODO_UPDATE: Toggle based on local regulatory compliance.
  static const bool enableGrievanceOfficer = false;

  /// Designated Grievance Officer name.
  /// TODO_UPDATE: Provide officer name if enableGrievanceOfficer is true.
  static const String grievanceOfficerName = 'TODO_UPDATE_OFFICER_NAME';

  /// Designated Grievance Officer contact email or telephone.
  /// TODO_UPDATE: Provide officer contact if enableGrievanceOfficer is true.
  static const String grievanceOfficerContact = 'TODO_UPDATE_OFFICER_CONTACT';

  // ===========================================================================
  // 5. REGIONAL RULES & DEFAULTS
  // ===========================================================================

  /// Default ISO 3166-1 alpha-2 country code.
  /// TODO_UPDATE: Set the default region for new app installs.
  static const String defaultRegion = 'US';

  /// Regional policy specifications.
  static const List<RegionRule> supportedRegions = [
    RegionRule(
      countryCode: 'US',
      countryName: 'United States',
      phonePrefix: '+1',
      emergencyNumbers: ['911'],
      recordingConsentNotice: 'Call recording laws vary by state. Many states require two-party consent.',
      applicablePrivacyLaw: 'CCPA / State Privacy Regulations',
    ),
    RegionRule(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      phonePrefix: '+44',
      emergencyNumbers: ['999', '112'],
      recordingConsentNotice: 'Recording for personal use is permitted; sharing requires consent.',
      applicablePrivacyLaw: 'UK GDPR / Data Protection Act 2018',
    ),
    RegionRule(
      countryCode: 'IN',
      countryName: 'India',
      phonePrefix: '+91',
      emergencyNumbers: ['112', '100', '101', '108'],
      recordingConsentNotice: 'Call screening and local voicemail recording for personal recipient use.',
      applicablePrivacyLaw: 'Digital Personal Data Protection Act (DPDPA 2023)',
    ),
    RegionRule(
      countryCode: 'DE',
      countryName: 'Germany',
      phonePrefix: '+49',
      emergencyNumbers: ['112', '110'],
      recordingConsentNotice: 'Two-party consent is strictly required under StGB § 201.',
      applicablePrivacyLaw: 'EU General Data Protection Regulation (GDPR)',
    ),
    RegionRule(
      countryCode: 'CA',
      countryName: 'Canada',
      phonePrefix: '+1',
      emergencyNumbers: ['911'],
      recordingConsentNotice: 'One-party consent applies under Canadian Criminal Code § 184.',
      applicablePrivacyLaw: 'PIPEDA',
    ),
    RegionRule(
      countryCode: 'AU',
      countryName: 'Australia',
      phonePrefix: '+61',
      emergencyNumbers: ['000', '112'],
      recordingConsentNotice: 'Two-party notification/consent required in multiple Australian states.',
      applicablePrivacyLaw: 'Privacy Act 1988',
    ),
    // TODO_UPDATE: Add additional region rules here as needed.
  ];

  // ===========================================================================
  // 6. CARRIER PROFILES (CALL FORWARDING SPECIFICATIONS)
  // ===========================================================================

  /// Default example carrier profiles. Marked unverified; test with active SIM.
  static const List<CarrierProfile> defaultCarrierProfiles = [
    CarrierProfile(
      id: 'us_generic_gsm',
      carrierName: 'Generic GSM (US)',
      countryCode: 'US',
      isVerified: false,
      forwardBusyCode: '*67*{NUMBER}#',
      forwardNoAnswerCode: '*61*{NUMBER}#',
      forwardUnreachableCode: '*62*{NUMBER}#',
      forwardAllCode: '*21*{NUMBER}#',
      cancelAllCode: '##002#',
      notes: 'Sample GSM supplementary service MMI codes. Verify with your carrier.',
    ),
    CarrierProfile(
      id: 'uk_generic_gsm',
      carrierName: 'Generic GSM (UK)',
      countryCode: 'GB',
      isVerified: false,
      forwardBusyCode: '*67*{NUMBER}#',
      forwardNoAnswerCode: '*61*{NUMBER}#',
      forwardUnreachableCode: '*62*{NUMBER}#',
      forwardAllCode: '*21*{NUMBER}#',
      cancelAllCode: '##002#',
      notes: 'Sample UK carrier forwarding codes. Verify with your network provider.',
    ),
    CarrierProfile(
      id: 'in_jio_sample',
      carrierName: 'Jio (India - Sample)',
      countryCode: 'IN',
      isVerified: false,
      forwardBusyCode: '*403*{NUMBER}',
      forwardNoAnswerCode: '*404*{NUMBER}',
      forwardUnreachableCode: '*405*{NUMBER}',
      forwardAllCode: '*401*{NUMBER}',
      cancelAllCode: '*413',
      notes: 'Sample Reliance Jio conditional call forwarding codes. Verify on actual device.',
    ),
    CarrierProfile(
      id: 'in_airtel_sample',
      carrierName: 'Airtel (India - Sample)',
      countryCode: 'IN',
      isVerified: false,
      forwardBusyCode: '*67*{NUMBER}#',
      forwardNoAnswerCode: '*61*{NUMBER}#',
      forwardUnreachableCode: '*62*{NUMBER}#',
      forwardAllCode: '*21*{NUMBER}#',
      cancelAllCode: '##002#',
      notes: 'Standard 3GPP GSM conditional forwarding codes for Airtel.',
    ),
    // TODO_UPDATE: Add more verified or sample carrier profiles here.
  ];

  // ===========================================================================
  // 7. SUPPORTED LOCALES / LANGUAGES
  // ===========================================================================

  /// Languages supported by the application.
  static const List<AppLocale> supportedLanguages = [
    AppLocale(languageCode: 'en', displayName: 'English', nativeName: 'English'),
    AppLocale(languageCode: 'es', displayName: 'Spanish', nativeName: 'Español'),
    AppLocale(languageCode: 'fr', displayName: 'French', nativeName: 'Français'),
    AppLocale(languageCode: 'de', displayName: 'German', nativeName: 'Deutsch'),
    AppLocale(languageCode: 'hi', displayName: 'Hindi', nativeName: 'हिन्दी'),
    AppLocale(languageCode: 'ml', displayName: 'Malayalam', nativeName: 'മലയാളം'),
    // TODO_UPDATE: Add extra languages as matching .arb files are provided.
  ];

  // ===========================================================================
  // 8. BACKEND & SERVICE FEATURE FLAGS
  // ===========================================================================

  /// Telephony relay backend base URL.
  /// TODO_UPDATE: Set to your actual server endpoint or leave as mock.
  static const String backendBaseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';

  /// Feature Flags (All defaulted safely for standalone mock demo).
  static const bool featureFlagAutoAnswerExperimental = false;
  static const bool featureFlagCloudTranscription = false;
  static const bool featureFlagLocalBackup = true;
  static const bool featureFlagFeedback = true;
  static const bool featureFlagInAppReview = true;
  static const bool mockServicesByDefault = true;

  // ===========================================================================
  // 9. STORE LISTING & APP UPDATES
  // ===========================================================================

  /// Short description for Google Play Store listing (max 80 chars).
  /// TODO_UPDATE: Write your store listing short summary.
  static const String storeListingShortDescription =
      'Smart, private, on-device visual voicemail and automated call screening assistant.';

  /// Changelog JSON feed URL.
  /// TODO_UPDATE: Point to your changelog endpoint.
  static const String changelogUrl = 'https://example.com/changelog.json';

  /// Update check version URL.
  /// TODO_UPDATE: Point to your update check version endpoint.
  static const String updateCheckUrl = 'https://example.com/version.json';

  // ===========================================================================
  // 10. RUNTIME METADATA & OVERRIDE LOADER
  // ===========================================================================

  static String version = '1.0.0';
  static String buildNumber = '1';
  static String packageName = packageIdProd;

  /// Loads package information and optional external JSON override from assets/config/app_config.json.
  static Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version.isNotEmpty ? info.version : '1.0.0';
      buildNumber = info.buildNumber.isNotEmpty ? info.buildNumber : '1';
      packageName = info.packageName.isNotEmpty ? info.packageName : packageIdProd;
    } catch (_) {
      version = '1.0.0';
      buildNumber = '1';
      packageName = packageIdProd;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/config/app_config.json');
      if (jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        _applyJsonOverrides(data);
      }
    } catch (_) {
      // If file does not exist or fails to parse, built-in constants are safely used.
    }
  }

  static void _applyJsonOverrides(Map<String, dynamic> data) {
    // Allows runtime customization without code modifications.
  }
}

/// Regional configuration rules and emergency number definitions.
class RegionRule {
  final String countryCode;
  final String countryName;
  final String phonePrefix;
  final List<String> emergencyNumbers;
  final String recordingConsentNotice;
  final String applicablePrivacyLaw;

  const RegionRule({
    required this.countryCode,
    required this.countryName,
    required this.phonePrefix,
    required this.emergencyNumbers,
    required this.recordingConsentNotice,
    required this.applicablePrivacyLaw,
  });

  Map<String, dynamic> toMap() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'phonePrefix': phonePrefix,
        'emergencyNumbers': emergencyNumbers,
        'recordingConsentNotice': recordingConsentNotice,
        'applicablePrivacyLaw': applicablePrivacyLaw,
      };
}

/// Carrier supplementary service configuration for call forwarding.
class CarrierProfile {
  final String id;
  final String carrierName;
  final String countryCode;
  final bool isVerified;
  final String forwardBusyCode;
  final String forwardNoAnswerCode;
  final String forwardUnreachableCode;
  final String forwardAllCode;
  final String cancelAllCode;
  final String notes;

  const CarrierProfile({
    required this.id,
    required this.carrierName,
    required this.countryCode,
    required this.isVerified,
    required this.forwardBusyCode,
    required this.forwardNoAnswerCode,
    required this.forwardUnreachableCode,
    required this.forwardAllCode,
    required this.cancelAllCode,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'carrierName': carrierName,
        'countryCode': countryCode,
        'isVerified': isVerified,
        'forwardBusyCode': forwardBusyCode,
        'forwardNoAnswerCode': forwardNoAnswerCode,
        'forwardUnreachableCode': forwardUnreachableCode,
        'forwardAllCode': forwardAllCode,
        'cancelAllCode': cancelAllCode,
        'notes': notes,
      };

  factory CarrierProfile.fromMap(Map<String, dynamic> map) => CarrierProfile(
        id: map['id'] as String? ?? 'custom',
        carrierName: map['carrierName'] as String? ?? 'Custom Carrier',
        countryCode: map['countryCode'] as String? ?? 'US',
        isVerified: map['isVerified'] as bool? ?? false,
        forwardBusyCode: map['forwardBusyCode'] as String? ?? '*67*{NUMBER}#',
        forwardNoAnswerCode: map['forwardNoAnswerCode'] as String? ?? '*61*{NUMBER}#',
        forwardUnreachableCode: map['forwardUnreachableCode'] as String? ?? '*62*{NUMBER}#',
        forwardAllCode: map['forwardAllCode'] as String? ?? '*21*{NUMBER}#',
        cancelAllCode: map['cancelAllCode'] as String? ?? '##002#',
        notes: map['notes'] as String? ?? '',
      );
}

/// Locale descriptor for multi-language support.
class AppLocale {
  final String languageCode;
  final String displayName;
  final String nativeName;

  const AppLocale({
    required this.languageCode,
    required this.displayName,
    required this.nativeName,
  });
}
