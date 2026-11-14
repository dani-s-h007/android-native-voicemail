import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openDeveloperWebsite() async {
    final uri = Uri.parse(AppConfig.developerWebsite);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:${AppConfig.supportEmail}?subject=Vani%20Voicemail%20Support');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri);
    } else {
      if (context.mounted) {
        context.showSnackBar('Support email: ${AppConfig.supportEmail}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'About Vani Voicemail',
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          // App Logo & Identity Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.voicemail_rounded,
                    size: 46,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                AppSpacing.vSpace16,
                Text(
                  AppConfig.appName,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.vSpace4,
                Text(
                  'Version ${AppConfig.version} (Build ${AppConfig.buildNumber})',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vSpace8,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '100% On-Device • Zero Cloud Storage',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace24,

          // Creator & Developer Card
          AppCard(
            variant: AppCardVariant.filled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      child: const Text('DK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    AppSpacing.hSpace14,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConfig.developerName,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.vSpace2,
                          Text(
                            'Lead Product Designer & Principal Engineer',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpace16,
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  icon: const Icon(Icons.language),
                  label: const Text('Visit Portfolio: danishk.web.app'),
                  onPressed: _openDeveloperWebsite,
                ),
                AppSpacing.vSpace8,
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: Text('Contact: ${AppConfig.supportEmail}'),
                  onPressed: () => _sendEmail(context),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace20,

          // Actions Category
          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              children: [
                AppListTile(
                  leading: const Icon(Icons.system_update_rounded),
                  title: const Text('Check for Updates'),
                  subtitle: const Text('Running latest stable corporate release'),
                  onTap: () {
                    context.showSnackBar('You are on the latest release: v${AppConfig.version}');
                  },
                ),
                const Divider(),
                AppListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Open-Source Licenses'),
                  subtitle: const Text('Flutter, Riverpod, Drift, and community libraries'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: AppConfig.appName,
                      applicationVersion: AppConfig.version,
                      applicationLegalese: '© 2026 ${AppConfig.developerName}. All rights reserved.',
                    );
                  },
                ),
              ],
            ),
          ),
          AppSpacing.vSpace20,

          // Changelog Card
          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHANGELOG • V1.0.0 (INITIAL RELEASE)',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                AppSpacing.vSpace12,
                _buildChangelogItem('• Google Material 3 design system with dynamic color theming.'),
                _buildChangelogItem('• 100% On-Device local SQLite storage; zero permanent cloud backups.'),
                _buildChangelogItem('• Native Indian VoLTE carrier forwarding (*403/*67#) for Jio & Airtel.'),
                _buildChangelogItem('• Offline multilingual speech transcripts in English, Hindi, and Malayalam.'),
                _buildChangelogItem('• Background watchdog service protecting against aggressive OEM task killers.'),
              ],
            ),
          ),
          AppSpacing.vSpace24,
        ],
      ),
    );
  }

  Widget _buildChangelogItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
    );
  }
}
