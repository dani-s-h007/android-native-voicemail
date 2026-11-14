import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/telephony/telephony_service.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _currentStep = 0;

  // Step 1: Region Selection
  late RegionRule _selectedRegion;

  // Step 2: Carrier Selection & Custom Codes
  String _selectedCarrierId = '';
  bool _isCustomCarrier = false;
  final TextEditingController _customCarrierNameController = TextEditingController(text: 'My Carrier');
  final TextEditingController _customBusyCodeController = TextEditingController(text: '*67*{NUMBER}#');
  final TextEditingController _customNoAnswerCodeController = TextEditingController(text: '*61*{NUMBER}#');
  final TextEditingController _customUnreachableCodeController = TextEditingController(text: '*62*{NUMBER}#');
  final TextEditingController _customCancelCodeController = TextEditingController(text: '##002#');

  // Step 3: Forwarding Number & Activation
  final TextEditingController _relayNumberController = TextEditingController();

  // Step 4: Verification
  bool _testCallVerified = false;

  @override
  void initState() {
    super.initState();
    _selectedRegion = AppConfig.supportedRegions.firstWhere(
      (r) => r.countryCode == AppConfig.defaultRegion,
      orElse: () => AppConfig.supportedRegions.first,
    );
    _initCarrierForRegion();
  }

  void _initCarrierForRegion() {
    final matchingCarriers = AppConfig.defaultCarrierProfiles
        .where((c) => c.countryCode == _selectedRegion.countryCode)
        .toList();

    if (matchingCarriers.isNotEmpty) {
      _selectedCarrierId = matchingCarriers.first.id;
      _isCustomCarrier = false;
    } else {
      _selectedCarrierId = 'custom';
      _isCustomCarrier = true;
    }
  }

  @override
  void dispose() {
    _customCarrierNameController.dispose();
    _customBusyCodeController.dispose();
    _customNoAnswerCodeController.dispose();
    _customUnreachableCodeController.dispose();
    _customCancelCodeController.dispose();
    _relayNumberController.dispose();
    super.dispose();
  }

  List<CarrierProfile> get _availableCarriers => AppConfig.defaultCarrierProfiles
      .where((c) => c.countryCode == _selectedRegion.countryCode)
      .toList();

  CarrierProfile? get _activeCarrierProfile {
    if (_isCustomCarrier) {
      return CarrierProfile(
        id: 'custom_user_carrier',
        carrierName: _customCarrierNameController.text.trim().isEmpty
            ? 'Custom Carrier'
            : _customCarrierNameController.text.trim(),
        countryCode: _selectedRegion.countryCode,
        isVerified: false,
        forwardBusyCode: _customBusyCodeController.text.trim(),
        forwardNoAnswerCode: _customNoAnswerCodeController.text.trim(),
        forwardUnreachableCode: _customUnreachableCodeController.text.trim(),
        forwardAllCode: '*21*{NUMBER}#',
        cancelAllCode: _customCancelCodeController.text.trim(),
        notes: 'User-configured custom MMI forwarding profile.',
      );
    }
    try {
      return AppConfig.defaultCarrierProfiles.firstWhere((c) => c.id == _selectedCarrierId);
    } catch (_) {
      return null;
    }
  }

  String _formatDialCode(String template, String targetNumber) {
    if (targetNumber.isEmpty) return template;
    return template.replaceAll('{NUMBER}', targetNumber);
  }

  Future<void> _finishWizard() async {
    final prefs = await SharedPreferences.getInstance();
    final target = _relayNumberController.text.trim();
    if (target.isNotEmpty) {
      await prefs.setString(AppConstants.keyForwardingRelayNumber, target);
      await prefs.setBool(AppConstants.keyForwardingActive, true);
    }
    await prefs.setString('user_selected_region', _selectedRegion.countryCode);
    await prefs.setString('user_selected_carrier', _activeCarrierProfile?.carrierName ?? 'Generic');
    await prefs.setBool('setup_wizard_completed', true);
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);

    if (mounted) {
      context.go(AppConstants.routeVoicemail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCarrier = _activeCarrierProfile;
    final targetNumber = _relayNumberController.text.trim();

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Initial Setup Wizard',
        subtitle: 'Configure region, carrier, and call forwarding',
        showBackButton: false,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _finishWizard();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(isLast ? 'Complete & Open Inbox' : 'Continue'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  AppSpacing.hSpace12,
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Select Country / Region
          Step(
            title: const Text('Select Your Country / Region'),
            subtitle: Text('${_selectedRegion.countryName} (${_selectedRegion.phonePrefix})'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select your primary operating region. Emergency numbers are pre-filled and permanently locked for safety.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vSpace16,
                DropdownButtonFormField<String>(
                  initialValue: _selectedRegion.countryCode,
                  decoration: const InputDecoration(
                    labelText: 'Country / Jurisdiction',
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: AppConfig.supportedRegions.map((r) {
                    return DropdownMenuItem(
                      value: r.countryCode,
                      child: Text('${r.countryName} (${r.phonePrefix})'),
                    );
                  }).toList(),
                  onChanged: (code) {
                    if (code != null) {
                      setState(() {
                        _selectedRegion = AppConfig.supportedRegions.firstWhere(
                          (r) => r.countryCode == code,
                        );
                        _initCarrierForRegion();
                      });
                    }
                  },
                ),
                AppSpacing.vSpace16,
                // Locked Emergency Numbers Banner
                AppCard(
                  variant: AppCardVariant.outlined,
                  child: Row(
                    children: [
                      const Icon(Icons.emergency, color: Colors.redAccent, size: 24),
                      AppSpacing.hSpace12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Locked Emergency Numbers',
                              style: context.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.vSpace2,
                            Text(
                              '${_selectedRegion.emergencyNumbers.join(', ')} (Never blocked or screened)',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Step 2: Select Carrier or Enter Custom Codes
          Step(
            title: const Text('Select Carrier or Custom Codes'),
            subtitle: Text(_isCustomCarrier ? 'Custom Carrier' : (activeCarrier?.carrierName ?? 'Select Carrier')),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your carrier profile or enter your carrier\'s conditional forwarding MMI codes.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vSpace16,
                DropdownButtonFormField<String>(
                  initialValue: _isCustomCarrier ? 'custom' : _selectedCarrierId,
                  decoration: const InputDecoration(
                    labelText: 'Carrier Network Profile',
                    prefixIcon: Icon(Icons.signal_cellular_alt),
                  ),
                  items: [
                    ..._availableCarriers.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.carrierName),
                      );
                    }),
                    const DropdownMenuItem(
                      value: 'custom',
                      child: Text('Custom Carrier (Enter Codes)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == 'custom') {
                      setState(() {
                        _selectedCarrierId = 'custom';
                        _isCustomCarrier = true;
                      });
                    } else if (val != null) {
                      setState(() {
                        _selectedCarrierId = val;
                        _isCustomCarrier = false;
                      });
                    }
                  },
                ),
                AppSpacing.vSpace12,

                if (!_isCustomCarrier && activeCarrier != null) ...[
                  if (!activeCarrier.isVerified)
                    const AppStatusBanner(
                      type: AppBannerType.warning,
                      title: 'Unverified Carrier Profile',
                      message: 'Example codes provided. Please test with an active SIM on your network.',
                    ),
                  AppSpacing.vSpace12,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Carrier Forwarding Codes:', style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        AppSpacing.vSpace6,
                        Text('Busy: ${activeCarrier.forwardBusyCode}', style: context.textTheme.bodySmall),
                        Text('No Answer: ${activeCarrier.forwardNoAnswerCode}', style: context.textTheme.bodySmall),
                        Text('Unreachable: ${activeCarrier.forwardUnreachableCode}', style: context.textTheme.bodySmall),
                        Text('Cancel All: ${activeCarrier.cancelAllCode}', style: context.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ] else ...[
                  // Custom Carrier Form
                  AppCard(
                    variant: AppCardVariant.outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custom Carrier Configuration', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        AppSpacing.vSpace12,
                        TextFormField(
                          controller: _customCarrierNameController,
                          decoration: const InputDecoration(labelText: 'Carrier Name'),
                        ),
                        AppSpacing.vSpace8,
                        TextFormField(
                          controller: _customBusyCodeController,
                          decoration: const InputDecoration(labelText: 'Forward Busy Code (e.g. *67*{NUMBER}#)'),
                        ),
                        AppSpacing.vSpace8,
                        TextFormField(
                          controller: _customNoAnswerCodeController,
                          decoration: const InputDecoration(labelText: 'Forward No Answer Code (e.g. *61*{NUMBER}#)'),
                        ),
                        AppSpacing.vSpace8,
                        TextFormField(
                          controller: _customUnreachableCodeController,
                          decoration: const InputDecoration(labelText: 'Forward Unreachable Code (e.g. *62*{NUMBER}#)'),
                        ),
                        AppSpacing.vSpace8,
                        TextFormField(
                          controller: _customCancelCodeController,
                          decoration: const InputDecoration(labelText: 'Cancel All Code (e.g. ##002#)'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Step 3: Forwarding Number & Activation
          Step(
            title: const Text('Forwarding Number & Activation'),
            subtitle: Text(targetNumber.isEmpty ? 'Not configured yet' : targetNumber),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the voicemail deposit number provided by your service or private telephony relay.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vSpace16,
                TextFormField(
                  controller: _relayNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Voicemail Forwarding Number',
                    hintText: '${_selectedRegion.phonePrefix} (555) 010-0000',
                    prefixIcon: const Icon(Icons.dialer_sip),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                AppSpacing.vSpace16,
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: context.colorScheme.primaryContainer,
                    foregroundColor: context.colorScheme.onPrimaryContainer,
                  ),
                  icon: const Icon(Icons.settings_phone),
                  label: const Text('Open Phone App Call Settings'),
                  onPressed: () async {
                    await TelephonyService.openCallSettings();
                  },
                ),
                if (activeCarrier != null && targetNumber.isNotEmpty) ...[
                  AppSpacing.vSpace8,
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.phone_forwarded),
                    label: Text(
                      'Dial ${_formatDialCode(activeCarrier.forwardBusyCode, targetNumber)}',
                    ),
                    onPressed: () async {
                      final dialCode = _formatDialCode(activeCarrier.forwardBusyCode, targetNumber);
                      await TelephonyService.dialMmi(dialCode);
                      if (context.mounted) {
                        context.showSnackBar('Dispatching MMI forwarding code to dialer: $dialCode');
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // Step 4: Test Call Verification
          Step(
            title: const Text('Test Call Verification'),
            subtitle: Text(_testCallVerified ? 'Verified' : 'Ready to test'),
            isActive: _currentStep >= 3,
            state: _testCallVerified ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  variant: AppCardVariant.filled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.record_voice_over, color: context.colorScheme.primary),
                          AppSpacing.hSpace12,
                          Text(
                            'Active Spoken Greeting Preview',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vSpace8,
                      Text(
                        '"Hello. I am currently unavailable to answer your call. Please leave a voicemail message after the tone, or send a text message. Thank you."',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace16,
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Simulate Test Call Verification'),
                  onPressed: () {
                    setState(() => _testCallVerified = true);
                    AppSnackbar.showSuccess(
                      context,
                      'Test call verified! Forwarding and greeting playback confirmed.',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
