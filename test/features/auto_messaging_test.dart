import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/features/call_modes/domain/auto_reply_rules.dart';
import 'package:voicemail/features/call_modes/presentation/controllers/auto_messaging_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoReplyRules Domain Tests', () {
    test('AutoMsgTargetMode fromId parses correctly', () {
      expect(AutoMsgTargetMode.fromId('ALL'), AutoMsgTargetMode.all);
      expect(AutoMsgTargetMode.fromId('SELECTED_ONLY'), AutoMsgTargetMode.selectedOnly);
      expect(AutoMsgTargetMode.fromId('UNSAVED_ONLY'), AutoMsgTargetMode.unsavedOnly);
      expect(AutoMsgTargetMode.fromId('EXCLUDE_SELECTED'), AutoMsgTargetMode.excludeSelected);
      expect(AutoMsgTargetMode.fromId('INVALID'), AutoMsgTargetMode.all);
    });

    test('AutoReplyContact cleans and compares phone numbers accurately', () {
      const c1 = AutoReplyContact(name: 'Alex', number: '+1 (555) 123-4567');
      const c2 = AutoReplyContact(name: 'Alex Doe', number: '5551234567');
      expect(c1.cleanNumber, '5551234567');
      expect(c2.cleanNumber, '5551234567');
      expect(c1, equals(c2));
    });

    test('AutoReplyPreset contains valid presets without emojis', () {
      expect(AutoReplyPreset.presets.length, greaterThanOrEqualTo(4));
      final general = AutoReplyPreset.presets.firstWhere((p) => p.title == 'General');
      expect(general.template, contains('unavailable'));
    });
  });

  group('AutoMessagingController State & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads defaults correctly', () async {
      final controller = AutoMessagingController();
      await controller.loadSettings();

      expect(controller.state.targetMode, AutoMsgTargetMode.all);
      expect(controller.state.selectedContacts, isEmpty);
      expect(controller.state.whatsAppNumber, isEmpty);
      expect(controller.state.emergencyBreakthrough, isTrue);
    });

    test('Adding and removing contacts persists to SharedPreferences', () async {
      final controller = AutoMessagingController();
      await controller.loadSettings();

      const contact = AutoReplyContact(name: 'Jordan', number: '+15559876543');
      await controller.addContact(contact);

      expect(controller.state.selectedContacts.length, 1);
      expect(controller.state.selectedContacts.first.cleanNumber, '5559876543');

      final prefs = await SharedPreferences.getInstance();
      final numbersJson = prefs.getString(AutoMessagingController.keyNumbers);
      expect(numbersJson, contains('5559876543'));

      await controller.removeContact(contact);
      expect(controller.state.selectedContacts, isEmpty);
    });

    test('Preview message dynamically appends messaging link when configured', () async {
      final controller = AutoMessagingController();
      await controller.loadSettings();
      await controller.setCustomMessage('Currently occupied.');
      await controller.toggleIncludeWhatsApp(true);
      await controller.setWhatsAppNumber('+15551234567');

      final preview = controller.state.previewMessage;
      expect(preview, contains('Currently occupied.'));
      expect(preview, contains('Chat: https://wa.me/15551234567'));
      expect(preview, contains('If urgent, call back within 3 mins'));
    });
  });
}
