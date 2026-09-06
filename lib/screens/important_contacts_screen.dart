import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImportantContactsScreen extends StatefulWidget {
  const ImportantContactsScreen({super.key});

  @override
  State<ImportantContactsScreen> createState() => _ImportantContactsScreenState();
}

class _ImportantContactsScreenState extends State<ImportantContactsScreen> {
  List<Contact> _contacts = [];
  bool _permissionDenied = false;
  List<String> _selectedPhoneNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _loadSelectedContacts();
  }

  Future<void> _loadSelectedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedString = prefs.getString('important_contacts') ?? '';
    if (savedString.isNotEmpty) {
      setState(() {
        _selectedPhoneNumbers = savedString.split(',');
      });
    }
  }

  Future<void> _saveSelectedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final stringToSave = _selectedPhoneNumbers.join(',');
    await prefs.setString('important_contacts', stringToSave);
  }

  Future<void> _fetchContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() => _permissionDenied = true);
      return;
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    setState(() => _contacts = contacts);
  }

  void _toggleContact(Contact contact) {
    if (contact.phones.isEmpty) return;
    
    // Just use the first phone number for simplicity, stripped of formatting
    final phone = contact.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '');
    
    setState(() {
      if (_selectedPhoneNumbers.contains(phone)) {
        _selectedPhoneNumbers.remove(phone);
      } else {
        _selectedPhoneNumbers.add(phone);
      }
    });
    
    _saveSelectedContacts();
  }
  
  bool _isSelected(Contact contact) {
    if (contact.phones.isEmpty) return false;
    final phone = contact.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '');
    return _selectedPhoneNumbers.contains(phone);
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Important Contacts')),
        body: const Center(
          child: Text('Permission denied to read contacts.'),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Important Contacts')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Important Contacts'),
      ),
      body: ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          final hasPhone = contact.phones.isNotEmpty;
          final subtitle = hasPhone ? contact.phones.first.number : 'No phone number';
          
          return ListTile(
            title: Text(contact.displayName),
            subtitle: Text(subtitle),
            trailing: _isSelected(contact) 
              ? const Icon(Icons.star, color: Colors.amber) 
              : const Icon(Icons.star_border),
            onTap: hasPhone ? () => _toggleContact(contact) : null,
          );
        },
      ),
    );
  }
}
