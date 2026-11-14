import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/core/telephony/telephony_service.dart';

class ForwardingScreen extends StatefulWidget {
  final String systemForwardingNumber;

  const ForwardingScreen({
    super.key,
    this.systemForwardingNumber = '+918040000000',
  });

  @override
  State<ForwardingScreen> createState() => _ForwardingScreenState();
}

class _ForwardingScreenState extends State<ForwardingScreen> {
  String _carrierName = 'Detecting...';
  List<Map<String, dynamic>> _activeSims = [];
  int _selectedSubId = -1;
  bool _isForwardingActive = false;
  bool _isLoading = false;
  String _relayNumber = '+918040000000';

  final List<String> _consoleLogs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _relayNumber = widget.systemForwardingNumber;
    _initCarrierAndStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _log(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _consoleLogs.add('[$time] $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initCarrierAndStatus() async {
    _log('Initializing telephony environment...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRelay = prefs.getString('forwarding_relay_number');
      if (savedRelay != null && savedRelay.trim().isNotEmpty) {
        _relayNumber = savedRelay.trim();
      }

      final carrier = await TelephonyService.getCarrierName();
      final sims = await TelephonyService.getActiveSims();
      final isActive = prefs.getBool('forwarding_active') ?? false;

      setState(() {
        _carrierName = carrier.isNotEmpty ? carrier : 'Unknown Carrier';
        _activeSims = sims;
        if (sims.isNotEmpty) {
          _selectedSubId = (sims.first['subId'] as int?) ?? -1;
        }
        _isForwardingActive = isActive;
      });

      _log('Detected Carrier: $_carrierName');
      _log('Configured Relay Number: $_relayNumber');
      if (sims.isNotEmpty) {
        _log('Active SIM slots: ${sims.length} (Selected SubId: $_selectedSubId)');
      } else {
        _log('Active SIM: Single / Default Subscription');
      }
      _log('Current Forwarding Status: ${isActive ? "ACTIVE" : "INACTIVE"}');
    } catch (e) {
      _log('Error initializing SIM info: $e');
    }
  }

  List<String> _buildMmiCodes({required bool enable, required String carrierName, required String didDigits}) {
    final carrierLower = carrierName.toLowerCase();
    if (enable) {
      if (carrierLower.contains('jio')) {
        // Jio VoLTE codes (Busy *403, No reply *402, Unreachable *409)
        return ['*403*$didDigits', '*402*$didDigits', '*409*$didDigits'];
      } else {
        // Standard GSM MMI for Airtel, Vi, BSNL
        return ['*67*$didDigits#', '*61*$didDigits#', '*62*$didDigits#'];
      }
    } else {
      if (carrierLower.contains('jio')) {
        return ['*413']; // Jio cancel all
      } else {
        return ['##002#']; // GSM cancel all
      }
    }
  }

  Future<void> _executeForwarding({required bool enable, required bool useDialerDirect}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final didDigits = _relayNumber.replaceAll('+', '').replaceAll(' ', '');

    _log('--------------------------------------------------');
    _log(enable
        ? 'Starting Activation: ${useDialerDirect ? "Direct Dialer" : "Background USSD"}'
        : 'Starting Deactivation (Cancel all forwarding)...');

    final codes = _buildMmiCodes(
      enable: enable,
      carrierName: _carrierName,
      didDigits: didDigits,
    );

    final primaryCode = codes.first;
    _log('Carrier target: $_carrierName');
    _log('Relay Destination DID: $didDigits');
    _log('Primary MMI Code: $primaryCode (SubID: $_selectedSubId)');

    try {
      Map<String, dynamic> result;

      if (useDialerDirect) {
        _log('Dispatching MMI code to native phone dialer...');
        result = await TelephonyService.dialMmi(primaryCode, subId: _selectedSubId);
      } else {
        _log('Sending background USSD to Android TelephonyManager (4s timeout guard)...');
        result = await TelephonyService.sendUssd(primaryCode, subId: _selectedSubId);
      }

      final status = result['status'] ?? 'UNKNOWN';
      final message = result['message'] ?? 'No response message';

      _log('Result Status: $status');
      _log('Carrier Message: $message');

      if (status == 'SUCCESS' || status == 'FALLBACK_DIALER' || status == 'TIMEOUT_FALLBACK') {
        await prefs.setBool('forwarding_active', enable);
        setState(() {
          _isForwardingActive = enable;
        });

        if (status == 'FALLBACK_DIALER' || status == 'TIMEOUT_FALLBACK') {
          _log('Notice: Indian VoLTE (Jio/Airtel) processes call forwarding via dialer.');
          _log('Your phone dialer has triggered the carrier prompt.');
        } else {
          _log('Network MMI successfully acknowledged by carrier.');
        }
      } else {
        _log('Failed or returned error: $message');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
            backgroundColor: (status == 'ERROR') ? Colors.red : Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      _log('Unexpected Exception during activation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Execution error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Guaranteed spinner stop
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _log('Operation completed. Spinner stopped.');
      _log('--------------------------------------------------');
    }
  }

  void _editRelayNumber() {
    final controller = TextEditingController(text: _relayNumber);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Relay Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The Relay Number is the Voicemail Server phone number (or your test phone) that answers forwarded calls.\n\n'
              'Enter your Asterisk DID, test mobile, or virtual number (with country code):',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Relay Phone Number',
                hintText: '+918040000000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_in_talk),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNum = controller.text.trim();
              if (newNum.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('forwarding_relay_number', newNum);
                setState(() => _relayNumber = newNum);
                _log('Relay number updated to: $newNum');
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearConsole() {
    setState(() {
      _consoleLogs.clear();
      _consoleLogs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] Console cleared.');
    });
  }

  void _copyConsoleLogs() {
    Clipboard.setData(ClipboardData(text: _consoleLogs.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Console logs copied to clipboard')),
    );
  }

  void _showTestCallDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How Voicemail Forwarding Works'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Your Mobile Number:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('This is your personal SIM. Callers ring this number.'),
            SizedBox(height: 8),
            Text('2. Relay Server Number:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('This is the assistant server that answers when you decline or miss a call.'),
            SizedBox(height: 8),
            Text('3. How to verify:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Call your phone from a friend\'s mobile.\n• Tap "Decline" or let it ring out.\n• Your carrier forwards the call to the Relay Number.\n• The caller hears your greeting and records their message.\n• The recording is delivered directly to this app.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrier Forwarding Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How it works',
            onPressed: _showTestCallDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Concept Clarification Card
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'What is the Relay Number?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Your SIM: Callers dial your regular phone number.\n'
                    '• Relay Number: The dedicated voicemail server number that answers when you are busy or reject a call.',
                    style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Forwarding Status Card
          Card(
            color: _isForwardingActive ? Colors.green.shade50 : Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _isForwardingActive ? Colors.green : Colors.amber.shade700),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    _isForwardingActive ? Icons.check_circle : Icons.phone_paused,
                    color: _isForwardingActive ? Colors.green.shade800 : Colors.amber.shade900,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isForwardingActive ? 'Voicemail Forwarding Active' : 'Forwarding Not Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _isForwardingActive ? Colors.green.shade900 : Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Carrier: $_carrierName\nRelay DID: $_relayNumber',
                          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit Relay Number',
                    onPressed: _editRelayNumber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Multi-SIM Selector (if multiple SIMs present)
          if (_activeSims.length > 1) ...[
            const Text('Select SIM Card to Configure:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _selectedSubId,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _activeSims.map((sim) {
                final name = sim['displayName'] ?? 'SIM';
                final carrier = sim['carrierName'] ?? '';
                final subId = sim['subId'] as int;
                return DropdownMenuItem<int>(
                  value: subId,
                  child: Text('$name ($carrier)'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSubId = val);
                  _log('Selected SIM SubId changed to: $val');
                }
              },
            ),
            const SizedBox(height: 14),
          ],

          // Primary Activation Button: Native Dialer (Instant for Jio/Realme)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: _isForwardingActive ? Colors.red.shade700 : Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(_isForwardingActive ? Icons.phone_disabled : Icons.dialer_sip),
            label: Text(
              _isLoading
                  ? 'Processing MMI...'
                  : _isForwardingActive
                      ? 'Deactivate / Cancel Forwarding'
                      : 'Activate via Phone Dialer (Recommended)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            onPressed: _isLoading
                ? null
                : () => _executeForwarding(
                      enable: !_isForwardingActive,
                      useDialerDirect: true,
                    ),
          ),
          const SizedBox(height: 8),

          // Secondary Option: Background USSD
          if (!_isForwardingActive) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.flash_on, size: 18),
              label: const Text('Try Background USSD (Silent Mode)'),
              onPressed: _isLoading
                  ? null
                  : () => _executeForwarding(
                        enable: true,
                        useDialerDirect: false,
                      ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            const SizedBox(height: 14),
          ],

          // Real-time Console Log Header & Box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal, size: 18, color: Colors.black87),
                  SizedBox(width: 6),
                  Text(
                    'Execution Console',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy Console Logs',
                    onPressed: _copyConsoleLogs,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Clear Console',
                    onPressed: _clearConsole,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Dark Monospace Console Box
          Container(
            height: 190,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: _consoleLogs.isEmpty
                ? const Center(
                    child: Text(
                      'Ready. Tap "Activate" or "Deactivate" to view real-time logs.',
                      style: TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _consoleLogs.length,
                    itemBuilder: (context, index) {
                      final line = _consoleLogs[index];
                      Color textColor = const Color(0xFF4AF626); // Terminal bright green
                      if (line.contains('Error') || line.contains('Failed') || line.contains('Exception')) {
                        textColor = Colors.redAccent.shade100;
                      } else if (line.contains('Notice') || line.contains('timeout') || line.contains('Starting')) {
                        textColor = Colors.amberAccent.shade200;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Carrier Reference Table
          const Text(
            'Reference: Indian Carrier MMI Codes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(1.8),
              1: FlexColumnWidth(3.2),
              2: FlexColumnWidth(1.8),
            },
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFEEEEEE)),
                children: [
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Carrier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Forward When Busy/No Reply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Jio (VoLTE)', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('*403*DID / *402*DID', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('*413', style: TextStyle(fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Airtel', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('*67*DID# / *61*DID#', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('##002#', style: TextStyle(fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6.0), child: Text('Vi', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('*67*DID# / *61*DID#', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('##002#', style: TextStyle(fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(6.0), child: Text('BSNL', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('*67*DID# / *61*DID#', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(6.0), child: Text('##002#', style: TextStyle(fontSize: 12))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
