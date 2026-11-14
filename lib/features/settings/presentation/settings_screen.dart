import 'dart:convert';
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
import 'package:voicemail/features/voicemail/presentation/controllers/voicemail_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _displayName = 'Jane Doe';
  String _phoneNumber = '+1 (555) 019-2831';
  String _secondaryNumber = '';
  String _selectedRegionCode = AppConfig.defaultRegion;
  String _selectedCarrierId = 'sample';
  String _carrierName = 'Carrier Default';
  String _selectedLanguage = 'English';

  bool _notificationsEnabled = true;
  bool _vibrateOnVoicemail = true;
  bool _priorityAlerts = true;
  String _notificationSound = 'Default Chime';

  int _retentionDays = 30;
  bool _blockScreenCapture = false;
  String _storageUsage = '0.4 MB';
  String _backupLocation = 'Internal Storage / Documents';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final name = prefs.getString(AppConstants.keyUserDisplayName) ?? 'Jane Doe';
      final phone = prefs.getString(AppConstants.keyUserPhoneNumber) ?? '+1 (555) 019-2831';
      final secPhone = prefs.getString(AppConstants.keyUserSecondaryNumber) ?? '';
      final region = prefs.getString(AppConstants.keySelectedRegion) ?? AppConfig.defaultRegion;
      final carrier = prefs.getString(AppConstants.keySelectedCarrier) ?? 'sample';
      final lang = prefs.getString(AppConstants.keySelectedLanguage) ?? 'English';

      final notif = prefs.getBool('notifications_enabled') ?? true;
      final vibrate = prefs.getBool(AppConstants.keyVibrateOnVoicemail) ?? true;
      final priority = prefs.getBool(AppConstants.keyPriorityAlerts) ?? true;
      final sound = prefs.getString(AppConstants.keyNotificationSound) ?? 'Default Chime';

      final days = prefs.getInt('retention_days') ?? 30;
      final block = prefs.getBool(AppConstants.keyBlockScreenCapture) ?? false;
      final backupLoc = prefs.getString(AppConstants.keyBackupLocation) ?? 'Internal Storage / Documents';

      final bytes = await LocalAudioStorage.getTotalStorageBytes();
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);

      // Resolve carrier name
      String resolvedCarrier = 'Carrier Default';
      final matched = AppConfig.defaultCarrierProfiles.where((c) => c.id == carrier).toList();
      if (matched.isNotEmpty) {
        resolvedCarrier = matched.first.carrierName;
      } else if (carrier == 'custom') {
        resolvedCarrier = prefs.getString('custom_carrier_name') ?? 'Custom Carrier';
      }

      if (mounted) {
        setState(() {
          _displayName = name;
          _phoneNumber = phone;
          _secondaryNumber = secPhone;
          _selectedRegionCode = region;
          _selectedCarrierId = carrier;
          _carrierName = resolvedCarrier;
          _selectedLanguage = lang;

          _notificationsEnabled = notif;
          _vibrateOnVoicemail = vibrate;
          _priorityAlerts = priority;
          _notificationSound = sound;

          _retentionDays = days;
          _blockScreenCapture = block;
          _storageUsage = '$mb MB';
          _backupLocation = backupLoc;

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAccountField(String title, String initialValue, void Function(String) onSave) async {
    final controller = TextEditingController(text: initialValue);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: title,
            hintText: 'Enter $title...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final value = controller.text.trim();
      onSave(value);
    }
  }

  Future<void> _setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserDisplayName, name);
    setState(() => _displayName = name);
    if (mounted) context.showSnackBar('Display name updated.');
  }

  Future<void> _setPhoneNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserPhoneNumber, phone);
    setState(() => _phoneNumber = phone);
    if (mounted) context.showSnackBar('Phone number updated.');
  }

  Future<void> _setSecondaryNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserSecondaryNumber, phone);
    setState(() => _secondaryNumber = phone);
    if (mounted) context.showSnackBar('Secondary number updated.');
  }

  Future<void> _setRetention(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('retention_days', days);
    setState(() => _retentionDays = days);
    if (mounted) context.showSnackBar('Retention updated to ${days == 0 ? 'Forever' : '$days days'}.');
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

    final backupData = {
      'app_name': AppConfig.appName,
      'app_version': AppConfig.version,
      'exported_at': DateTime.now().toIso8601String(),
      'account': {
        'display_name': _displayName,
        'phone_number': _phoneNumber,
        'region': _selectedRegionCode,
        'carrier': _selectedCarrierId,
      },
      'settings': {
        'retention_days': _retentionDays,
        'language': _selectedLanguage,
        'block_screen_capture': _blockScreenCapture,
      },
      'voicemails': voicemails.map((v) => {
        'id': v.id,
        'caller_name': v.displayName,
        'caller_number': v.callerNumber,
        'duration_seconds': v.durationSeconds,
        'transcript': v.transcriptText,
        'created_at': v.createdAt.toIso8601String(),
        'is_read': v.isRead,
        'is_starred': v.isStarred,
      }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    await Share.share(
      jsonString,
      subject: '${AppConfig.appName} Local Backup Export',
    );
  }

  Future<void> _restoreBackup() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Restore Backup Data?',
      message: 'This will merge or restore voicemails and application preferences from your chosen backup file.',
      confirmLabel: 'Restore',
    );

    if (confirmed == true && mounted) {
      context.showSnackBar('Backup restored successfully (mock mode).');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final useDynamicColor = ref.watch(useDynamicColorProvider);

    final activeRegion = AppConfig.supportedRegions.firstWhere(
      (r) => r.countryCode == _selectedRegionCode,
      orElse: () => AppConfig.supportedRegions.first,
    );

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
                // 1. App Identity Card
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
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
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

                // 2. Account Profile Section
                _buildSectionHeader('USER ACCOUNT & PROFILE'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Display Name'),
                        subtitle: Text(
                          _displayName.isNotEmpty ? _displayName : 'Empty, tap to set up',
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => _updateAccountField('Display Name', _displayName, _setDisplayName),
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Primary Phone Number'),
                        subtitle: Text(
                          _phoneNumber.isNotEmpty ? _phoneNumber : 'Empty, tap to set up',
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => _updateAccountField('Primary Phone Number', _phoneNumber, _setPhoneNumber),
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.phone_iphone_outlined),
                        title: const Text('Secondary Number / SIM 2'),
                        subtitle: Text(
                          _secondaryNumber.isNotEmpty ? _secondaryNumber : 'Empty, tap to set up',
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => _updateAccountField('Secondary Number', _secondaryNumber, _setSecondaryNumber),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 3. Region and Carrier Section
                _buildSectionHeader('REGION & CARRIER'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.public, color: Colors.blue),
                        title: const Text('Default Region & Carrier Profile'),
                        subtitle: Text(
                          '${activeRegion.countryName} (${activeRegion.countryCode}) • $_carrierName',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await context.push('/region-carrier');
                          await _loadSettings();
                        },
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.emergency_outlined, color: Colors.red),
                        title: const Text('Emergency Numbers (Locked)'),
                        subtitle: Text(
                          '${activeRegion.emergencyNumbers.join(', ')} (Exempt from screening)',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LOCKED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.settings_phone_outlined, color: Colors.teal),
                        title: const Text('Open System Phone Call Settings'),
                        subtitle: const Text('Configure conditional forwarding directly on SIM'),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => TelephonyService.openCallSettings(),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 4. Notifications & Sounds
                _buildSectionHeader('NOTIFICATIONS & SOUNDS'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppSwitchRow(
                        leading: const Icon(Icons.notifications_outlined),
                        title: 'Voicemail Notifications',
                        subtitle: 'Alert when a caller leaves an audio message',
                        value: _notificationsEnabled,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notifications_enabled', val);
                          setState(() => _notificationsEnabled = val);
                        },
                      ),
                      const Divider(),
                      AppSwitchRow(
                        leading: const Icon(Icons.vibration),
                        title: 'Vibrate on Voicemail',
                        subtitle: 'Vibrate when a new transcript arrives',
                        value: _vibrateOnVoicemail,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(AppConstants.keyVibrateOnVoicemail, val);
                          setState(() => _vibrateOnVoicemail = val);
                        },
                      ),
                      const Divider(),
                      AppSwitchRow(
                        leading: const Icon(Icons.priority_high),
                        title: 'Priority Screening Alerts',
                        subtitle: 'Heads-up notification while assistant screens a call',
                        value: _priorityAlerts,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(AppConstants.keyPriorityAlerts, val);
                          setState(() => _priorityAlerts = val);
                        },
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.music_note_outlined),
                        title: const Text('Notification Sound'),
                        subtitle: Text(_notificationSound),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showNotificationSoundDialog(context),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 5. Appearance Section
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

                // 6. Language Section
                _buildSectionHeader('APPLICATION LANGUAGE'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: AppListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('App Display Language'),
                    subtitle: Text('$_selectedLanguage (${_getLanguageNativeName(_selectedLanguage)})'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageDialog(context),
                  ),
                ),
                AppSpacing.vSpace20,

                // 7. Privacy & Local Storage
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
                        subtitle: 'Prevent screenshots and recordings of private voicemails',
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

                // 8. Backup & Restore
                _buildSectionHeader('BACKUP & RESTORE'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.file_upload_outlined),
                        title: const Text('Export Local Backup'),
                        subtitle: const Text('Export JSON with voicemails, transcripts & settings'),
                        trailing: const Icon(Icons.share, size: 18),
                        onTap: _exportBackup,
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.file_download_outlined),
                        title: const Text('Restore Backup from Local File'),
                        subtitle: const Text('Import voicemails and configurations'),
                        trailing: const Icon(Icons.restore, size: 18),
                        onTap: _restoreBackup,
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: const Text('Backup Location'),
                        subtitle: Text(_backupLocation),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => _updateAccountField(
                          'Backup Storage Location',
                          _backupLocation,
                          (loc) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(AppConstants.keyBackupLocation, loc);
                            setState(() => _backupLocation = loc);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace20,

                // 9. System Health & Diagnostics
                _buildSectionHeader('SYSTEM HEALTH & DIAGNOSTICS'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.health_and_safety_outlined, color: Colors.green),
                        title: const Text('Reliability & Battery Check'),
                        subtitle: const Text('Check background screening exemptions and permissions'),
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

                // 10. Legal Hub & About
                _buildSectionHeader('HELP & ABOUT'),
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Column(
                    children: [
                      AppListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Help & Support'),
                        subtitle: const Text('Contact support (${AppConfig.supportEmail})'),
                        trailing: const Icon(Icons.mail_outline, size: 18),
                        onTap: () async {
                          final uri = Uri.parse('mailto:${AppConfig.supportEmail}?subject=Support Request - ${AppConfig.appName}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.gavel_outlined),
                        title: const Text('Legal & Compliance Hub'),
                        subtitle: const Text('Terms, Privacy Policy, consent notice & legal contacts'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push('/legal/privacy'),
                      ),
                      const Divider(),
                      AppListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About ${AppConfig.appName}'),
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

  String _getLanguageNativeName(String displayName) {
    final match = AppConfig.supportedLanguages.where((l) => l.displayName == displayName);
    return match.isNotEmpty ? match.first.nativeName : displayName;
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
    showDialog<void>(
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

  void _showLanguageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Application Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppConfig.supportedLanguages.map((lang) {
              return ListTile(
                title: Text(lang.displayName),
                subtitle: Text(lang.nativeName),
                leading: const Icon(Icons.language),
                selected: _selectedLanguage == lang.displayName,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(AppConstants.keySelectedLanguage, lang.displayName);
                  setState(() => _selectedLanguage = lang.displayName);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showNotificationSoundDialog(BuildContext context) {
    final sounds = ['Default Chime', 'Gentle Bell', 'Modern Pulse', 'Subtle Pop', 'System Default'];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sounds.map((s) {
            return ListTile(
              title: Text(s),
              leading: const Icon(Icons.music_note_outlined),
              selected: _notificationSound == s,
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(AppConstants.keyNotificationSound, s);
                setState(() => _notificationSound = s);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRetentionDialog(BuildContext context) {
    showDialog<void>(
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
