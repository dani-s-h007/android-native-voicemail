import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicemail/app/app.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/storage/local_audio_storage.dart';
import 'package:voicemail/core/telephony/telephony_service.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/forwarding/presentation/forwarding_screen.dart';
import 'package:voicemail/features/voicemail/presentation/controllers/voicemail_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _retentionDays = 30;
  bool _blockScreenCapture = false;
  String _storageUsage = '0.4 MB';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getInt('retention_days') ?? 30;
      final block = prefs.getBool(AppConstants.keyBlockScreenCapture) ?? false;
      final bytes = await LocalAudioStorage.getTotalStorageBytes();
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);

      setState(() {
        _retentionDays = days;
        _blockScreenCapture = block;
        _storageUsage = '$mb MB';
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setRetention(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('retention_days', days);
    setState(() => _retentionDays = days);
    if (mounted) context.showSnackBar('Retention updated to $days days');
  }

  Future<void> _toggleScreenCapture(bool block) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyBlockScreenCapture, block);
    setState(() => _blockScreenCapture = block);
    if (mounted) {
      context.showSnackBar(
        block
            ? 'Screen capture blocked for voicemail privacy'
            : 'Screen capture allowed',
      );
    }
  }

  Future<void> _exportBackup() async {
    final voicemails = ref.read(voicemailControllerProvider).voicemails;
    if (voicemails.isEmpty) {
      context.showSnackBar('No voicemails available to export.');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Vani Voicemail Local Export ===');
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total messages: ${voicemails.length}');
    buffer.writeln('----------------------------------\n');

    for (final v in voicemails) {
      buffer.writeln('ID: ${v.id}');
      buffer.writeln('CALLER: ${v.displayName} (${v.callerNumber})');
      buffer.writeln('DATE: ${v.createdAt.toIso8601String()}');
      buffer.writeln('DURATION: ${v.durationSeconds}s');
      buffer.writeln('TRANSCRIPT: ${v.transcriptText ?? "N/A"}');
      buffer.writeln('----------------------------------');
    }

    await Share.share(buffer.toString(), subject: 'Vani Voicemail Backup');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final useDynamicColor = ref.watch(useDynamicColorProvider);

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Settings',
        subtitle: 'Preferences & System Controls',
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.padding16,
              children: [
                // 1. Account & App Identity Card
                AppCard(
                  variant: AppCardVariant.filled,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.voicemail_rounded,
                          size: 28,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      AppSpacing.hSpace16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConfig.appName,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.vSpace2,
                            Text(
                              AppConfig.appTagline,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.vSpace4,
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse(AppConfig.developerWebsiteUrl);
                                if (await canLaunchUrl(uri)) launchUrl(uri);
                              },
                              child: Text(
                                AppConfig.developerName.contains('TODO_UPDATE')
                                    ? AppConfig.appName
                                    : 'by ${AppConfig.developerName}',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 2. Appearance Section
                _buildSectionHeader('APPEARANCE & THEME'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Theme Mode'),
                        subtitle: Text(
                          themeMode == ThemeMode.system
                              ? 'System Default'
                              : themeMode == ThemeMode.dark
                                  ? 'Dark Theme'
                                  : 'Light Theme',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showThemeDialog(context),
                      ),
                      const Divider(),
                      AppSwitchRow(
                        leading: const Icon(Icons.palette_outlined),
                        title: 'Dynamic Color (Material You)',
                        subtitle: 'Extract palette from your phone wallpaper',
                        value: useDynamicColor,
                        onChanged: (val) {
                          ref.read(useDynamicColorProvider.notifier).state = val;
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 3. Telephony & Carrier Forwarding
                _buildSectionHeader('CARRIER & FORWARDING'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.settings_phone_outlined, color: Colors.teal),
                        title: const Text('Open Phone App Call Settings'),
                        subtitle: const Text('Configure "When busy" & "When unanswered" safely'),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => TelephonyService.openCallSettings(),
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.dialer_sip_outlined, color: Colors.deepPurple),
                        title: const Text('Carrier Forwarding Console'),
                        subtitle: const Text('View MMI logs, DID settings, and anti-deactivation shield'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForwardingScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // Smart Auto-Messaging Section
                _buildSectionHeader('AUTO-MESSAGING & SELECTED NUMBERS'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: AppListTile(
                    leading: const Icon(Icons.mark_chat_unread_outlined, color: Colors.blue),
                    title: const Text('Auto-Reply Rules & Whitelist'),
                    subtitle: const Text('Configure target callers, custom SMS, WhatsApp link & 2-call override'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/auto-messaging'),
                  ),
                ),
                AppSpacing.vSpace20,

                // 4. Privacy & Local Storage
                _buildSectionHeader('PRIVACY & LOCAL DATA (ZERO CLOUD)'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.hourglass_empty_rounded),
                        title: const Text('Audio Retention Period'),
                        subtitle: Text(
                          _retentionDays == 0 ? 'Keep forever' : '$_retentionDays days (Auto-purges old audio)',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showRetentionDialog(context),
                      ),
                      const Divider(),
                      AppSwitchRow(
                        leading: const Icon(Icons.security),
                        title: 'Block Screen Capture',
                        subtitle: 'Prevent screenshots of private voicemails',
                        value: _blockScreenCapture,
                        onChanged: _toggleScreenCapture,
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                        title: const Text('Delete All Voicemails', style: TextStyle(color: Colors.red)),
                        subtitle: Text('Local SQLite storage usage: $_storageUsage'),
                        onTap: () async {
                          final confirmed = await AppDialog.showConfirmation(
                            context: context,
                            title: 'Wipe All Voicemails?',
                            message:
                                'This will permanently remove all audio recordings and transcripts from your device.',
                            confirmLabel: 'Wipe All',
                            isDestructive: true,
                          );
                          if (confirmed == true) {
                            final allIds = ref
                                .read(voicemailControllerProvider)
                                .voicemails
                                .map((v) => v.id)
                                .toSet();
                            await ref
                                .read(voicemailControllerProvider.notifier)
                                .markSelectedAsRead(false);
                            if (allIds.isNotEmpty) {
                              await ref
                                  .read(voicemailRepositoryProvider)
                                  .deleteMultiple(allIds);
                              await ref
                                  .read(voicemailControllerProvider.notifier)
                                  .loadVoicemails();
                            }
                            if (context.mounted) {
                              context.showSnackBar('All local voicemails wiped.');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 5. Backup & Restore
                _buildSectionHeader('BACKUP & LOCAL EXPORT'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.file_upload_outlined),
                        title: const Text('Export Local Backup'),
                        subtitle: const Text('Share or save transcripts & metadata locally'),
                        trailing: const Icon(Icons.share, size: 18),
                        onTap: _exportBackup,
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 6. System Health & Diagnostics
                _buildSectionHeader('SYSTEM HEALTH & DIAGNOSTICS'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.health_and_safety_outlined, color: Colors.green),
                        title: const Text('Reliability & Battery Check'),
                        subtitle: const Text('Check Realme UI background exemptions & permissions'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/reliability'),
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.troubleshoot_rounded, color: Colors.blue),
                        title: const Text('Call Log Diagnostics'),
                        subtitle: const Text('"Why did this call not work?" decision trail'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/diagnostics'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 7. Legal Hub & About
                _buildSectionHeader('LEGAL & ABOUT'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.gavel_outlined),
                        title: const Text('Legal & Compliance Hub'),
                        subtitle: const Text('Terms, Privacy Policy, DPDP notice, and Grievance Officer'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/legal/privacy'),
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About Vani Voicemail'),
                        subtitle: Text('Version ${AppConfig.version} (Build ${AppConfig.buildNumber})'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/about'),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace32,
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: context.textTheme.labelMedium?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () {
                ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Light Theme'),
              leading: const Icon(Icons.light_mode),
              onTap: () {
                ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Dark Theme'),
              leading: const Icon(Icons.dark_mode),
              onTap: () {
                ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRetentionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Retention Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('30 Days (Recommended)'),
              onTap: () {
                _setRetention(30);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('60 Days'),
              onTap: () {
                _setRetention(60);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('90 Days'),
              onTap: () {
                _setRetention(90);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Keep Forever'),
              onTap: () {
                _setRetention(0);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
