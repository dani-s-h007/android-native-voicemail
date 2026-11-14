import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/telephony/telephony_service.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class RegionCarrierScreen extends ConsumerStatefulWidget {
  const RegionCarrierScreen({super.key});

  @override
  ConsumerState<RegionCarrierScreen> createState() => _RegionCarrierScreenState();
}

class _RegionCarrierScreenState extends ConsumerState<RegionCarrierScreen> {
  late String _selectedCountryCode;
  late String _selectedCarrierId;
  bool _isCustomCarrier = false;

  late final TextEditingController _customCarrierNameController;
  late final TextEditingController _busyCodeController;
  late final TextEditingController _noAnswerCodeController;
  late final TextEditingController _unreachableCodeController;
  late final TextEditingController _forwardAllCodeController;
  late final TextEditingController _cancelAllCodeController;
  late final TextEditingController _relayNumberController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = AppConfig.defaultRegion;
    _selectedCarrierId = AppConfig.defaultCarrierProfiles.first.id;

    _customCarrierNameController = TextEditingController(text: 'Custom Carrier');
    _busyCodeController = TextEditingController(text: '*67*{NUMBER}#');
    _noAnswerCodeController = TextEditingController(text: '*61*{NUMBER}#');
    _unreachableCodeController = TextEditingController(text: '*62*{NUMBER}#');
    _forwardAllCodeController = TextEditingController(text: '*21*{NUMBER}#');
    _cancelAllCodeController = TextEditingController(text: '##002#');
    _relayNumberController = TextEditingController(text: AppConstants.defaultVoicemailRelayNumber);

    _loadSavedSettings();
  }

  @override
  void dispose() {
    _customCarrierNameController.dispose();
    _busyCodeController.dispose();
    _noAnswerCodeController.dispose();
    _unreachableCodeController.dispose();
    _forwardAllCodeController.dispose();
    _cancelAllCodeController.dispose();
    _relayNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final region = prefs.getString(AppConstants.keySelectedRegion) ?? AppConfig.defaultRegion;
      final carrierId = prefs.getString(AppConstants.keySelectedCarrier) ?? _selectedCarrierId;
      final relay = prefs.getString(AppConstants.keyForwardingRelayNumber) ?? AppConstants.defaultVoicemailRelayNumber;

      final customName = prefs.getString('custom_carrier_name');
      final busy = prefs.getString('custom_forward_busy');
      final noAnswer = prefs.getString('custom_forward_no_answer');
      final unreachable = prefs.getString('custom_forward_unreachable');
      final forwardAll = prefs.getString('custom_forward_all');
      final cancelAll = prefs.getString('custom_cancel_all');

      if (mounted) {
        setState(() {
          _selectedCountryCode = region;
          _selectedCarrierId = carrierId;
          _isCustomCarrier = carrierId == 'custom';
          _relayNumberController.text = relay;

          if (customName != null) _customCarrierNameController.text = customName;
          if (busy != null) _busyCodeController.text = busy;
          if (noAnswer != null) _noAnswerCodeController.text = noAnswer;
          if (unreachable != null) _unreachableCodeController.text = unreachable;
          if (forwardAll != null) _forwardAllCodeController.text = forwardAll;
          if (cancelAll != null) _cancelAllCodeController.text = cancelAll;

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySelectedRegion, _selectedCountryCode);
      await prefs.setString(AppConstants.keySelectedCarrier, _selectedCarrierId);
      await prefs.setString(AppConstants.keyForwardingRelayNumber, _relayNumberController.text.trim());

      if (_isCustomCarrier) {
        await prefs.setString('custom_carrier_name', _customCarrierNameController.text.trim());
        await prefs.setString('custom_forward_busy', _busyCodeController.text.trim());
        await prefs.setString('custom_forward_no_answer', _noAnswerCodeController.text.trim());
        await prefs.setString('custom_forward_unreachable', _unreachableCodeController.text.trim());
        await prefs.setString('custom_forward_all', _forwardAllCodeController.text.trim());
        await prefs.setString('custom_cancel_all', _cancelAllCodeController.text.trim());
      }

      if (mounted) {
        context.showSnackBar('Region & Carrier preferences saved successfully.');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error saving settings: $e');
      }
    }
  }

  RegionRule get _activeRegion {
    return AppConfig.supportedRegions.firstWhere(
      (r) => r.countryCode == _selectedCountryCode,
      orElse: () => AppConfig.supportedRegions.first,
    );
  }

  List<CarrierProfile> get _availableCarriers {
    return AppConfig.defaultCarrierProfiles
        .where((c) => c.countryCode == _selectedCountryCode)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final region = _activeRegion;
    final carriers = _availableCarriers;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Region & Carrier Settings',
        subtitle: 'MMI Codes & Universal Telephony Relay',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.padding16,
              children: [
                // 1. Region Selection Card
                Text(
                  'DEFAULT REGION & RULES',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                AppSpacing.vSpace8,
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCountryCode),
                  initialValue: _selectedCountryCode,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.public),
                    labelText: 'Country / Jurisdiction',
                  ),
                  items: AppConfig.supportedRegions.map((r) {
                    return DropdownMenuItem(
                      value: r.countryCode,
                      child: Text('${r.countryName} (${r.phonePrefix})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCountryCode = val;
                        // Reset carrier selection to first matching carrier or custom
                        final matching = AppConfig.defaultCarrierProfiles
                            .where((c) => c.countryCode == val)
                            .toList();
                        if (matching.isNotEmpty) {
                          _selectedCarrierId = matching.first.id;
                          _isCustomCarrier = false;
                        } else {
                          _selectedCarrierId = 'custom';
                          _isCustomCarrier = true;
                        }
                      });
                    }
                  },
                ),
                AppSpacing.vSpace12,

                // Region Info & Privacy Card
                AppCard(
                  variant: AppCardVariant.filled,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: colorScheme.primary, size: 20),
                          AppSpacing.hSpace8,
                          Expanded(
                            child: Text(
                              'Privacy Framework: ${region.applicablePrivacyLaw}',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vSpace6,
                      Text(
                        region.recordingConsentNotice,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace12,

                // Locked Emergency Numbers Banner
                AppCard(
                  variant: AppCardVariant.outlined,
                  borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.red),
                      AppSpacing.hSpace12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Emergency Numbers',
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                Container(
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
                              ],
                            ),
                            AppSpacing.vSpace4,
                            Text(
                              region.emergencyNumbers.join(', '),
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            AppSpacing.vSpace4,
                            Text(
                              'Pre-filled from regional safety rules. Emergency calls are legally exempt and never screened or intercepted.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace24,

                // 2. Carrier Selection Card
                Text(
                  'MOBILE CARRIER PROFILE',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                AppSpacing.vSpace8,
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCarrierId),
                  initialValue: _selectedCarrierId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.cell_tower),
                    labelText: 'Select Carrier',
                  ),
                  items: [
                    ...carriers.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.isVerified ? c.carrierName : '${c.carrierName} (Sample)',
                        ),
                      );
                    }),
                    const DropdownMenuItem(
                      value: 'custom',
                      child: Text('Custom Carrier (Manual MMI Codes)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCarrierId = val;
                        _isCustomCarrier = val == 'custom';
                      });
                    }
                  },
                ),
                AppSpacing.vSpace12,

                // Active Carrier Notice / Disclaimer
                if (!_isCustomCarrier) ...[
                  const AppStatusBanner(
                    type: AppBannerType.info,
                    title: 'Sample Carrier Forwarding Codes',
                    message:
                        'Carrier codes provided are examples. Carrier MMI codes vary by plan and SIM. Test on your physical device before relying on call forwarding.',
                  ),
                  AppSpacing.vSpace12,
                ],

                // 3. Custom MMI Forwarding Codes Editor (if custom is selected or expandable)
                if (_isCustomCarrier) ...[
                  AppCard(
                    variant: AppCardVariant.filled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOM CARRIER MMI CODES',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        AppSpacing.vSpace4,
                        Text(
                          'Use {NUMBER} placeholder for your destination relay.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.vSpace16,
                        TextField(
                          controller: _customCarrierNameController,
                          decoration: const InputDecoration(
                            labelText: 'Carrier Name',
                            hintText: 'e.g. Acme Mobile',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                        ),
                        AppSpacing.vSpace12,
                        TextField(
                          controller: _busyCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Forward When Busy',
                            hintText: '*67*{NUMBER}#',
                            prefixIcon: Icon(Icons.phone_missed_outlined),
                          ),
                        ),
                        AppSpacing.vSpace12,
                        TextField(
                          controller: _noAnswerCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Forward When Unanswered',
                            hintText: '*61*{NUMBER}#',
                            prefixIcon: Icon(Icons.phone_paused_outlined),
                          ),
                        ),
                        AppSpacing.vSpace12,
                        TextField(
                          controller: _unreachableCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Forward When Unreachable',
                            hintText: '*62*{NUMBER}#',
                            prefixIcon: Icon(Icons.signal_cellular_connected_no_internet_0_bar),
                          ),
                        ),
                        AppSpacing.vSpace12,
                        TextField(
                          controller: _forwardAllCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Forward All (Unconditional)',
                            hintText: '*21*{NUMBER}#',
                            prefixIcon: Icon(Icons.phone_forwarded_outlined),
                          ),
                        ),
                        AppSpacing.vSpace12,
                        TextField(
                          controller: _cancelAllCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Cancel All Forwarding',
                            hintText: '##002#',
                            prefixIcon: Icon(Icons.cancel_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vSpace20,
                ],

                // 4. Voicemail Relay Destination
                Text(
                  'VOICEMAIL RELAY NUMBER',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                AppSpacing.vSpace8,
                TextField(
                  controller: _relayNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Relay Phone Number',
                    hintText: '+1 (555) 019-8765',
                    prefixIcon: Icon(Icons.dialer_sip_outlined),
                    helperText: 'Number configured in your telephony server or carrier profile.',
                  ),
                ),
                AppSpacing.vSpace20,

                // Quick Link to Phone Settings
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open System Phone Call Settings'),
                  onPressed: () => TelephonyService.openCallSettings(),
                ),
                AppSpacing.vSpace16,

                // 5. Save Button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save & Apply Telephony Profile'),
                  onPressed: _saveSettings,
                ),
                AppSpacing.vSpace32,
              ],
            ),
    );
  }
}
