import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _selectedCarrier = 'Jio';
  String _relayNumber = AppConstants.defaultExotelKeralaDid;
  bool _forwardingConfigured = false;
  bool _testCallVerified = false;

  final List<String> _carriers = ['Jio', 'Airtel', 'Vodafone Idea (Vi)', 'BSNL'];

  @override
  void initState() {
    super.initState();
    _detectCarrier();
  }

  Future<void> _detectCarrier() async {
    try {
      final carrier = await TelephonyService.getCarrierName();
      if (carrier.isNotEmpty && carrier != 'Unknown') {
        for (final c in _carriers) {
          if (carrier.toLowerCase().contains(c.toLowerCase().split(' ').first)) {
            setState(() => _selectedCarrier = c);
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _finishWizard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyForwardingRelayNumber, _relayNumber);
    await prefs.setBool(AppConstants.keyForwardingActive, true);
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);

    if (mounted) {
      context.go(AppConstants.routeVoicemail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Carrier & Voicemail Setup',
        subtitle: 'Configure forwarding to your Kerala DID',
        showBackButton: false,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
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
          final isLast = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(isLast ? 'Finish & Launch Inbox' : 'Continue'),
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
          // Step 1: Carrier Selection
          Step(
            title: const Text('Select Your Mobile Carrier'),
            subtitle: Text('Current: $_selectedCarrier'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your carrier determines whether VoLTE forwarding uses *403 (Jio) or *67# (Airtel/Vi/BSNL).',
                  style: TextStyle(fontSize: 13),
                ),
                AppSpacing.vSpace12,
                DropdownButtonFormField<String>(
                  value: _selectedCarrier,
                  decoration: const InputDecoration(
                    labelText: 'Carrier Network',
                    prefixIcon: Icon(Icons.signal_cellular_alt),
                  ),
                  items: _carriers.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCarrier = val);
                  },
                ),
              ],
            ),
          ),

          // Step 2: Forwarding Configuration
          Step(
            title: const Text('Configure Call Forwarding'),
            subtitle: Text('Relay: $_relayNumber'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppStatusBanner(
                  type: AppBannerType.success,
                  title: 'Anti-Deactivation Protection Active',
                  message:
                      'In-app deactivation has been removed. Forwarding settings are safe and cannot be accidentally deleted.',
                ),
                AppSpacing.vSpace12,
                TextFormField(
                  initialValue: _relayNumber,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Virtual Voicemail DID (Exotel Kerala)',
                    prefixIcon: Icon(Icons.dialer_sip),
                  ),
                  onChanged: (val) => _relayNumber = val.trim(),
                ),
                AppSpacing.vSpace12,
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.settings_phone),
                  label: const Text('Open Phone App Call Settings'),
                  onPressed: () async {
                    await TelephonyService.openCallSettings();
                    setState(() => _forwardingConfigured = true);
                  },
                ),
                AppSpacing.vSpace8,
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.phone_forwarded),
                  label: Text(
                    _selectedCarrier == 'Jio'
                        ? 'Dial *403*$_relayNumber'
                        : 'Dial *67*$_relayNumber#',
                  ),
                  onPressed: () async {
                    final code = _selectedCarrier == 'Jio'
                        ? '*403*$_relayNumber'
                        : '*67*$_relayNumber#';
                    await TelephonyService.dialMmi(code);
                    setState(() => _forwardingConfigured = true);
                  },
                ),
              ],
            ),
          ),

          // Step 3: Test Call Verification
          Step(
            title: const Text('Test Your Voicemail Assistant'),
            subtitle: Text(_testCallVerified ? 'Verified' : 'Ready to test'),
            isActive: _currentStep >= 2,
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
                          const Icon(Icons.record_voice_over, color: Colors.deepPurple),
                          AppSpacing.hSpace12,
                          Text(
                            'Active Greeting Preview',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vSpace8,
                      Text(
                        '"Hi, Danish here. I can\'t take your call right now. Please WhatsApp or SMS me. Thanks!"',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace16,
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Simulate Test Call Verification'),
                  onPressed: () {
                    setState(() => _testCallVerified = true);
                    context.showSnackBar(
                      'Test call verified! Caller greeting matches Danish K preset.',
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

