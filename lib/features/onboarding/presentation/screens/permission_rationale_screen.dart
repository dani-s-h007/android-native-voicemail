import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemail/app/di/service_providers.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class PermissionRationaleScreen extends ConsumerStatefulWidget {
  const PermissionRationaleScreen({super.key});

  @override
  ConsumerState<PermissionRationaleScreen> createState() =>
      _PermissionRationaleScreenState();
}

class _PermissionRationaleScreenState
    extends ConsumerState<PermissionRationaleScreen> {
  Map<String, bool> _statuses = {
    'callScreening': false,
    'phone': false,
    'contacts': false,
    'batteryExempt': false,
    'notifications': false,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final service = ref.read(permissionServiceProvider);
    final statuses = await service.checkAllPermissions();
    if (mounted) {
      setState(() {
        _statuses = statuses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(permissionServiceProvider);
    final isCallScreeningOk = _statuses['callScreening'] ?? false;
    final isPhoneOk = _statuses['phone'] ?? false;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Permissions & System Access',
        subtitle: 'Why we request each permission',
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.padding16,
              children: [
                AppStatusBanner(
                  type: isCallScreeningOk
                      ? AppBannerType.success
                      : AppBannerType.info,
                  title: isCallScreeningOk
                      ? 'Core Call Screening Ready'
                      : 'Essential Permissions Needed',
                  message:
                      'Android requires explicit consent before an app can manage call screening or run in the background.',
                ),
                AppSpacing.vSpace16,

                // 1. Call Screening Role
                AppPermissionCard(
                  icon: Icons.shield_outlined,
                  title: 'Call Screening Service',
                  description:
                      'Allows the app to evaluate incoming callers before your phone rings, letting Danish K\'s assistant answer spam or unavailable calls.',
                  isGranted: _statuses['callScreening'] ?? false,
                  actionLabel: 'Set Role',
                  onGrant: () async {
                    await service.requestCallScreeningRole();
                    await _refreshPermissions();
                  },
                ),
                AppSpacing.vSpace12,

                // 2. Phone State & Calls
                AppPermissionCard(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'Phone & Call State',
                  description:
                      'Required to detect missed or declined calls and interact with carrier supplementary services.',
                  isGranted: _statuses['phone'] ?? false,
                  actionLabel: 'Grant',
                  onGrant: () async {
                    await service.requestPhonePermission();
                    await _refreshPermissions();
                  },
                ),
                AppSpacing.vSpace12,

                // 3. Contacts
                AppPermissionCard(
                  icon: Icons.contacts_outlined,
                  title: 'Contacts (Recommended)',
                  description:
                      'Used solely to display caller names instead of raw numbers. Never synced to any cloud.',
                  isGranted: _statuses['contacts'] ?? false,
                  isMandatory: false,
                  actionLabel: 'Allow',
                  onGrant: () async {
                    await service.requestContactsPermission();
                    await _refreshPermissions();
                  },
                ),
                AppSpacing.vSpace12,

                // 4. Battery Optimization
                AppPermissionCard(
                  icon: Icons.battery_charging_full_outlined,
                  title: 'Battery Optimization Exemption',
                  description:
                      'Prevents aggressive OS battery managers (Realme UI, MIUI, ColorOS) from sleeping the background listener.',
                  isGranted: _statuses['batteryExempt'] ?? false,
                  isMandatory: false,
                  actionLabel: 'Exempt',
                  onGrant: () async {
                    await service.requestBatteryOptimizationExempt();
                    await _refreshPermissions();
                  },
                ),
                AppSpacing.vSpace12,

                // 5. Notifications
                AppPermissionCard(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  description:
                      'Displays instant heads-up alerts when a caller leaves a voicemail or when the assistant handles a call.',
                  isGranted: _statuses['notifications'] ?? false,
                  isMandatory: false,
                  actionLabel: 'Allow',
                  onGrant: () async {
                    await service.requestNotificationsPermission();
                    await _refreshPermissions();
                  },
                ),
                AppSpacing.vSpace24,

                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    context.go(AppConstants.routeSetupWizard);
                  },
                  child: Text(
                    isCallScreeningOk && isPhoneOk
                        ? 'Continue to Carrier Setup'
                        : 'Proceed Anyway',
                  ),
                ),
                AppSpacing.vSpace16,
              ],
            ),
    );
  }
}

