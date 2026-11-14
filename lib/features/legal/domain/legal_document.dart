import 'package:flutter/material.dart';

enum LegalDocType {
  privacy(
    id: 'privacy',
    title: 'Privacy Policy',
    subtitle: 'Zero permanent cloud storage policy & DPDP Act compliance',
    assetPath: 'assets/legal/privacy_policy.md',
    webUrl: 'https://danishk.web.app/privacy',
    icon: Icons.privacy_tip_outlined,
  ),
  terms(
    id: 'terms',
    title: 'Terms of Service',
    subtitle: 'Permitted communication rules and service scope',
    assetPath: 'assets/legal/terms_of_service.md',
    webUrl: 'https://danishk.web.app/terms',
    icon: Icons.description_outlined,
  ),
  dataSafety(
    id: 'data-safety',
    title: 'Google Play Data Safety',
    subtitle: 'Detailed data collection and sharing disclosure table',
    assetPath: 'assets/legal/data_safety.md',
    webUrl: 'https://danishk.web.app/data-safety',
    icon: Icons.shield_outlined,
  ),
  recordingNotice(
    id: 'recording-notice',
    title: 'Call Recording & Consent Notice',
    subtitle: 'Statutory caller notice under Indian Telegraph Act',
    assetPath: 'assets/legal/call_recording_notice.md',
    webUrl: 'https://danishk.web.app/recording-notice',
    icon: Icons.record_voice_over_outlined,
  ),
  permissions(
    id: 'permissions',
    title: 'Permissions Explanation',
    subtitle: 'Comprehensive breakdown of all requested Android permissions',
    assetPath: 'assets/legal/permissions_explanation.md',
    webUrl: 'https://danishk.web.app/permissions',
    icon: Icons.lock_open_outlined,
  ),
  disclaimer(
    id: 'disclaimer',
    title: 'Legal Disclaimer',
    subtitle: 'Carrier network interactions and transcription accuracy',
    assetPath: 'assets/legal/disclaimer.md',
    webUrl: 'https://danishk.web.app/disclaimer',
    icon: Icons.info_outline,
  ),
  grievanceOfficer(
    id: 'grievance',
    title: 'Grievance Officer Contact',
    subtitle: 'Statutory contact under IT Rules (2021) & DPDP (2023)',
    assetPath: 'assets/legal/grievance_officer.md',
    webUrl: 'https://danishk.web.app/grievance',
    icon: Icons.contact_mail_outlined,
  );

  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final String webUrl;
  final IconData icon;

  const LegalDocType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.webUrl,
    required this.icon,
  });

  static LegalDocType fromId(String id) {
    return LegalDocType.values.firstWhere(
      (d) => d.id == id,
      orElse: () => LegalDocType.privacy,
    );
  }
}

