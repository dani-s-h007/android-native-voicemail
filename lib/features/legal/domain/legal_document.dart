import 'package:flutter/material.dart';
import 'package:voicemail/app/config/app_config.dart';

enum LegalDocType {
  privacy(
    id: 'privacy',
    title: 'Privacy Policy',
    subtitle: 'Zero permanent cloud storage policy & regional privacy compliance',
    assetPath: 'assets/legal/privacy_policy.md',
    defaultUrlKey: 'privacy',
    icon: Icons.privacy_tip_outlined,
  ),
  terms(
    id: 'terms',
    title: 'Terms of Service',
    subtitle: 'Permitted communication rules and service scope',
    assetPath: 'assets/legal/terms_of_service.md',
    defaultUrlKey: 'terms',
    icon: Icons.description_outlined,
  ),
  dataSafety(
    id: 'data-safety',
    title: 'Google Play Data Safety',
    subtitle: 'Detailed data collection and sharing disclosure table',
    assetPath: 'assets/legal/data_safety.md',
    defaultUrlKey: 'data-safety',
    icon: Icons.shield_outlined,
  ),
  recordingNotice(
    id: 'recording-notice',
    title: 'Call Recording & Consent Notice',
    subtitle: 'Statutory caller notice and recording consent notice',
    assetPath: 'assets/legal/call_recording_notice.md',
    defaultUrlKey: 'recording-notice',
    icon: Icons.record_voice_over_outlined,
  ),
  permissions(
    id: 'permissions',
    title: 'Permissions Explanation',
    subtitle: 'Comprehensive breakdown of all requested Android permissions',
    assetPath: 'assets/legal/permissions_explanation.md',
    defaultUrlKey: 'permissions',
    icon: Icons.lock_open_outlined,
  ),
  disclaimer(
    id: 'disclaimer',
    title: 'Legal Disclaimer',
    subtitle: 'Carrier network interactions and transcription accuracy',
    assetPath: 'assets/legal/disclaimer.md',
    defaultUrlKey: 'disclaimer',
    icon: Icons.info_outline,
  ),
  grievanceOfficer(
    id: 'grievance',
    title: 'Grievance Officer Contact',
    subtitle: 'Designated compliance representative and grievance contact',
    assetPath: 'assets/legal/grievance_officer.md',
    defaultUrlKey: 'grievance',
    icon: Icons.contact_mail_outlined,
  );

  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final String defaultUrlKey;
  final IconData icon;

  const LegalDocType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.defaultUrlKey,
    required this.icon,
  });

  String get webUrl {
    switch (this) {
      case LegalDocType.privacy:
        return AppConfig.privacyPolicyUrl;
      case LegalDocType.terms:
        return AppConfig.termsUrl;
      case LegalDocType.dataSafety:
        return AppConfig.dataSafetyUrl;
      case LegalDocType.recordingNotice:
        return AppConfig.recordingNoticeUrl;
      case LegalDocType.permissions:
        return '${AppConfig.developerWebsiteUrl}/permissions';
      case LegalDocType.disclaimer:
        return '${AppConfig.developerWebsiteUrl}/disclaimer';
      case LegalDocType.grievanceOfficer:
        return '${AppConfig.developerWebsiteUrl}/grievance';
    }
  }

  static LegalDocType fromId(String id) {
    return LegalDocType.values.firstWhere(
      (d) => d.id == id,
      orElse: () => LegalDocType.privacy,
    );
  }
}
