import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreedToTerms = false;
  bool _agreedToRecordingNotice = false;

  bool get _canProceed => _agreedToTerms && _agreedToRecordingNotice;

  Future<void> _submitConsent() async {
    if (!_canProceed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyConsentAccepted, true);

    if (mounted) {
      context.go(AppConstants.routePermissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Privacy & Consent Notice',
        showBackButton: false,
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: colorScheme.primary, size: 24),
                    AppSpacing.hSpace12,
                    Text(
                      'Indian Telecommunications & DPDP Compliance',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpace12,
                Text(
                  'To respect caller privacy and comply with Indian law, please review our core privacy standards:',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // Point 1: Zero Cloud Storage
          _buildPrivacyPoint(
            icon: Icons.cloud_off_outlined,
            title: '1. Zero Permanent Cloud Storage',
            description:
                'We do not operate permanent cloud storage. Once audio is forwarded to your phone, it is purged from relays and exists exclusively in your phone\'s local database.',
          ),
          AppSpacing.vSpace12,

          // Point 2: Transparent Caller Notice
          _buildPrivacyPoint(
            icon: Icons.campaign_outlined,
            title: '2. Transparent Caller Notice',
            description:
                'Callers are explicitly informed through your greeting that you are unavailable and prompted before leaving a voicemail or WhatsApp/SMS message.',
          ),
          AppSpacing.vSpace12,

          // Point 3: User Rights & Local Deletion
          _buildPrivacyPoint(
            icon: Icons.delete_forever_outlined,
            title: '3. Full Control & Instant Erasure',
            description:
                'You maintain 100% ownership of your recordings. You can export, backup, or instantly wipe all voicemails from settings with zero residual server trace.',
          ),
          AppSpacing.vSpace24,

          // Checkboxes
          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              children: [
                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  title: const Text('I agree to the Terms of Service and Privacy Policy'),
                  subtitle: const Text('Read in full via Settings > Legal Hub'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                CheckboxListTile(
                  value: _agreedToRecordingNotice,
                  onChanged: (val) =>
                      setState(() => _agreedToRecordingNotice = val ?? false),
                  title: const Text('I consent to automated call greeting & on-device transcription'),
                  subtitle: const Text('Complies with Indian Telecommunications Act'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          AppSpacing.vSpace24,

          // Proceed Button
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _canProceed ? _submitConsent : null,
            child: const Text('Agree & Continue'),
          ),
          AppSpacing.vSpace16,
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colorScheme.primary, size: 24),
          AppSpacing.hSpace14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.vSpace4,
                Text(
                  description,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

