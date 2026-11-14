import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/legal/domain/legal_document.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String documentId;

  const LegalDocumentScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String _markdownContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _markdownContent = _processTokens('# Loading...\n\nPlease wait.');
    _loadDocument();
  }

  String _processTokens(String raw) {
    final region = AppConfig.supportedRegions.firstWhere(
      (r) => r.countryCode == AppConfig.defaultRegion,
      orElse: () => AppConfig.supportedRegions.first,
    );

    return raw
        .replaceAll('{{APP_NAME}}', AppConfig.appName)
        .replaceAll('{{COMPANY_NAME}}', AppConfig.companyLegalName)
        .replaceAll('{{DEVELOPER_NAME}}', AppConfig.developerName)
        .replaceAll('{{DEVELOPER_WEBSITE}}', AppConfig.developerWebsiteUrl)
        .replaceAll('{{SUPPORT_EMAIL}}', AppConfig.supportEmail)
        .replaceAll('{{COMPANY_ADDRESS}}', AppConfig.companyAddress)
        .replaceAll('{{DEFAULT_REGION}}', region.countryName)
        .replaceAll('{{EFFECTIVE_DATE}}', AppConfig.legalEffectiveDate)
        .replaceAll('{{APPLICABLE_PRIVACY_LAW}}', region.applicablePrivacyLaw)
        .replaceAll('{{GRIEVANCE_OFFICER_NAME}}', AppConfig.grievanceOfficerName)
        .replaceAll('{{GRIEVANCE_OFFICER_CONTACT}}', AppConfig.grievanceOfficerContact);
  }

  Future<void> _loadDocument() async {
    final doc = LegalDocType.fromId(widget.documentId);
    try {
      final content = await rootBundle.loadString(doc.assetPath);
      if (mounted) {
        setState(() {
          _markdownContent = _processTokens(content);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _markdownContent = _processTokens(
            '# ${doc.title}\n\n'
            '${doc.subtitle}\n\n'
            'Please review the official online document at: ${doc.webUrl}',
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWebVersion(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) context.showErrorSnackBar('Unable to open web version');
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = LegalDocType.fromId(widget.documentId);

    return AppScaffold(
      appBar: AppAppBar(
        title: doc.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'View Online',
            onPressed: () => _openWebVersion(doc.webUrl),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.padding16,
              children: [
                AppCard(
                  variant: AppCardVariant.filled,
                  child: Row(
                    children: [
                      Icon(doc.icon, color: context.colorScheme.primary, size: 24),
                      AppSpacing.hSpace12,
                      Expanded(
                        child: Text(
                          'Official Legal Document • Compliance Notice',
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace16,

                // Markdown body
                SelectableText(
                  _markdownContent,
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                AppSpacing.vSpace24,

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Official Hosted Web Version'),
                  onPressed: () => _openWebVersion(doc.webUrl),
                ),
                AppSpacing.vSpace24,
              ],
            ),
    );
  }
}
