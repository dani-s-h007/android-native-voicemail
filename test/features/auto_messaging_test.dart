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
      const c1 = AutoReplyContact(name: 'Danish', number: '+91 79073 38556');
      const c2 = AutoReplyContact(name: 'Danish K', number: '07907338556');
      expect(c1.cleanNumber, '7907338556');
      expect(c2.cleanNumber, '7907338556');
      expect(c1, equals(c2));
    });

    test('AutoReplyPreset contains valid presets', () {
      expect(AutoReplyPreset.presets.length, greaterThanOrEqualTo(4));
      final classPreset = AutoReplyPreset.presets.firstWhere((p) => p.title.contains('Class'));
      expect(classPreset.template, contains('class/lecture'));
    });
  });

  group('AutoMessagingController State & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads defaults correctly', () async {
      final controller = AutoMessagingController();
      await controller.loadSettings();

      expect(controller.debugState.targetMode, AutoMsgTargetMode.all);
      expect(controller.debugState.selectedContacts, isEmpty);
      expect(controller.debugState.includeWhatsAppLink, isTrue);
      expect(controller.debugState.emergencyBreakthrough, isTrue);
    });

    test('Adding and removing contacts persists to SharedPreferences', () async {
      final controller = AutoMessagingController();
      await controller.loadSettings();

      const contact = AutoReplyContact(name: 'Ameen', number: '+91 94471 23456');
      await controller.addContact(contact);

      expect(controller.debugState.selectedContacts.length, 1);
      expect(controller.debugState.selectedContacts.first.cleanNumber, '9447123456');

      final prefs = await SharedPreferences.getInstance();
      final numbersJson = prefs.getString(AutoMessagingController.keyNumbers);
      expect(numbersJson, contains('9447123456'));

      await controller.removeContact(contact);
      expect(controller.debugState.selectedContacts, isEmpty);
    });

    test('Preview message dynamically appends WhatsApp link and Emergency note', () async {
      final controller = AutoMessagingController();
      await controller.loadSettings();
      await controller.setCustomMessage('In class right now.');

      final preview = controller.debugState.previewMessage;
      expect(preview, contains('In class right now.'));
      expect(preview, contains('WhatsApp: https://wa.me/917907338556'));
      expect(preview, contains('If urgent, call back within 3 mins'));
    });
  });
}
