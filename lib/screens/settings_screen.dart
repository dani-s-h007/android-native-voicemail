import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'important_contacts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _replyController = TextEditingController();
  int _selectedMethod = 1; // 1 = Silent Reject + SMS, 2 = Auto-Answer + TTS
  bool _sendSmsAfterTts = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _replyController.text = prefs.getString('auto_reply') ??
          'I am in class right now. Please text me.';
      _selectedMethod = prefs.getInt('selected_method') ?? 1;
      _sendSmsAfterTts = prefs.getBool('send_sms_after_tts') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_reply', _replyController.text);
    await prefs.setInt('selected_method', _selectedMethod);
    await prefs.setBool('send_sms_after_tts', _sendSmsAfterTts);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Call Handling Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RadioListTile<int>(
              title: const Text('Method 1: Silent Reject + SMS'),
              subtitle: const Text('Silently rejects the call and sends a text message.'),
              value: 1,
              groupValue: _selectedMethod,
              onChanged: (int? value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
            ),
            RadioListTile<int>(
              title: const Text('Method 2: Auto-Answer + TTS'),
              subtitle: const Text('Answers the call, speaks the message out loud via speakerphone, then hangs up.'),
              value: 2,
              groupValue: _selectedMethod,
              onChanged: (int? value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
            ),
            if (_selectedMethod == 2)
              SwitchListTile(
                title: const Text('Send SMS after hanging up'),
                value: _sendSmsAfterTts,
                onChanged: (bool value) {
                  setState(() {
                    _sendSmsAfterTts = value;
                  });
                },
              ),
            const Divider(height: 40),
            const Text(
              'Message Payload (SMS / TTS Text)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This text will be sent as an SMS or spoken out loud via TTS depending on your chosen method above.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your custom message here...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Important Contacts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Select contacts that bypass Class Mode'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportantContactsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 20),
            const Center(
              child: Column(
                children: [
                  Text(
                    'Developed by Danish K',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: InkWell(
                onTap: () async {
                  final url = Uri.parse('https://danishk.web.app');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    'danishk.web.app',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
