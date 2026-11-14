import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/call_modes/domain/call_mode.dart';
import 'package:voicemail/features/call_modes/presentation/controllers/modes_controller.dart';
import 'package:voicemail/features/call_modes/presentation/screens/call_modes_screen.dart';
import 'package:voicemail/features/greetings/domain/greeting_preset.dart';
import 'package:voicemail/features/greetings/presentation/controllers/greetings_controller.dart';
import 'package:voicemail/features/greetings/presentation/screens/greetings_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('CallHandlingMode & DND Logic Tests', () {
    test('All 4 CallHandlingMode values have titles, subtitles, and cost descriptions', () {
      expect(CallHandlingMode.values.length, 4);

      for (final mode in CallHandlingMode.values) {
        expect(mode.title.isNotEmpty, isTrue);
        expect(mode.subtitle.isNotEmpty, isTrue);
        expect(mode.costDescription.isNotEmpty, isTrue);
      }
    });

    test('DndExceptions maintains locked emergency numbers 112, 100, 108, 101', () {
      const exceptions = DndExceptions();
      expect(exceptions.emergencyNumbers, contains('112'));
      expect(exceptions.emergencyNumbers, contains('100'));
      expect(exceptions.emergencyNumbers, contains('108'));
      expect(exceptions.emergencyNumbers, contains('101'));
    });

    test('ModesController toggles assistant active and sets DND timer', () async {
      final controller = ModesController();
      expect(controller.state.isAssistantActive, isTrue);

      await controller.toggleAssistant(false);
      expect(controller.state.isAssistantActive, isFalse);

      await controller.startDndForDuration(const Duration(hours: 2));
      expect(controller.state.dndUntil, isNotNull);
      expect(controller.state.isDndActive, isTrue);

      await controller.cancelDnd();
      expect(controller.state.dndUntil, isNull);
    });

    test('ModesController manages whitelist numbers', () {
      final controller = ModesController();
      controller.addWhitelistNumber('+15551234567');
      expect(controller.state.exceptions.whitelistNumbers, contains('+15551234567'));

      controller.removeWhitelistNumber('+15551234567');
      expect(controller.state.exceptions.whitelistNumbers, isNot(contains('+15551234567')));
    });
  });

  group('GreetingsPreset & Controller Tests', () {
    test('Default presets include Meeting, Driving, Sleeping, Traveling, Custom, Hindi, and Malayalam', () {
      final presets = GreetingPreset.defaultPresets;
      expect(presets.length, greaterThanOrEqualTo(8));

      final hasMeeting = presets.any((p) => p.title.contains('Meeting'));
      final hasDriving = presets.any((p) => p.title.contains('Driving'));
      final hasSleeping = presets.any((p) => p.title.contains('Sleeping'));
      final hasTraveling = presets.any((p) => p.title.contains('Traveling'));
      final hasCustom = presets.any((p) => p.title.contains('Custom'));
      final hasHindi = presets.any((p) => p.language == 'Hindi');
      final hasMalayalam = presets.any((p) => p.language == 'Malayalam');
      final hasSpanish = presets.any((p) => p.language == 'Spanish');

      expect(hasMeeting, isTrue);
      expect(hasDriving, isTrue);
      expect(hasSleeping, isTrue);
      expect(hasTraveling, isTrue);
      expect(hasCustom, isTrue);
      expect(hasHindi, isTrue);
      expect(hasMalayalam, isTrue);
      expect(hasSpanish, isTrue);
    });

    test('Presets contain Danish greeting and no fixed personal phone numbers', () {
      final defaultPreset = GreetingPreset.defaultPresets.first;
      expect(defaultPreset.text, contains('Danish'));
      for (final preset in GreetingPreset.defaultPresets) {
        expect(preset.text.contains('7907338556'), isFalse);
      }
    });

    test('GreetingsController updates text, language, and contact group', () {
      final controller = GreetingsController();
      controller.updateText('Hello from universal voicemail');
      expect(controller.state.activeGreeting.text, 'Hello from universal voicemail');

      controller.setLanguage('Spanish');
      expect(controller.state.selectedLanguage, 'Spanish');

      controller.setGroup('Work & Clients');
      expect(controller.state.selectedGroup, 'Work & Clients');
    });

    test('GreetingsController manages voice recording simulation state', () {
      final controller = GreetingsController();
      expect(controller.state.isRecording, isFalse);
      expect(controller.state.recordedAudioPath, isNull);

      controller.startRecording();
      expect(controller.state.isRecording, isTrue);

      controller.stopRecording(savedPath: 'test_greeting.m4a');
      expect(controller.state.isRecording, isFalse);
      expect(controller.state.recordedAudioPath, 'test_greeting.m4a');

      controller.clearRecordedAudio();
      expect(controller.state.recordedAudioPath, isNull);
    });
  });

  group('Modes & Greetings Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: child,
        ),
      );
    }

    testWidgets('CallModesScreen renders status card, 4 mode cards, and locked emergency numbers', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const CallModesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Call Handling & DND'), findsOneWidget);
      expect(find.text('Standard Server Greeting Active'), findsOneWidget);

      // Verify mode cards
      expect(find.text('Standard Server Greeting'), findsOneWidget);
      expect(find.text('Auto-Decline with Message'), findsOneWidget);
      expect(find.text('Auto-Answer Assistant'), findsOneWidget);
      expect(find.text('Silent DND Mode'), findsOneWidget);

      // Verify quick DND duration chips
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('4h'), findsOneWidget);

      // Verify locked emergency services
      expect(find.textContaining('Emergency Numbers'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
    });

    testWidgets('GreetingsScreen renders active greeting card, presets, variable chips, and language picker', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const GreetingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Custom Greetings Hub'), findsOneWidget);
      expect(find.text('Smart TTS & Presets'), findsOneWidget);
      expect(find.text('Record Voice'), findsOneWidget);
      expect(find.text('Listen to Preview (TTS)'), findsOneWidget);
      expect(find.text('{name}'), findsOneWidget);
      expect(find.text('{caller}'), findsOneWidget);
      expect(find.text('{time_back}'), findsOneWidget);
      expect(find.text('{alternative_number}'), findsOneWidget);
      expect(find.text('Save Greeting on Device'), findsOneWidget);

      // Tap on the Record Voice tab
      await tester.tap(find.text('Record Voice'));
      await tester.pumpAndSettle();

      expect(find.text('Record Your Natural Voice'), findsOneWidget);
      expect(find.text('Start Recording'), findsOneWidget);
    });
  });
}
