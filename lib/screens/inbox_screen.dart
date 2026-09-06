import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _voicemails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVoicemails();
  }

  Future<void> _loadVoicemails() async {
    final voicemails = await _dbHelper.getVoicemails();
    setState(() {
      _voicemails = voicemails;
      _isLoading = false;
    });
  }

  Future<void> _deleteVoicemail(int id) async {
    await _dbHelper.deleteVoicemail(id);
    _loadVoicemails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voicemail Inbox'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _voicemails.isEmpty
              ? const Center(child: Text('No voicemails yet.'))
              : ListView.builder(
                  itemCount: _voicemails.length,
                  itemBuilder: (context, index) {
                    final voicemail = _voicemails[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(
                        voicemail['timestamp']);
                    return ListTile(
                      leading: const Icon(Icons.voicemail),
                      title: Text(voicemail['phoneNumber']),
                      subtitle: Text(
                          '${voicemail['message']}\n${date.toString().substring(0, 16)}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteVoicemail(voicemail['id']),
                      ),
                    );
                  },
                ),
    );
  }
}
