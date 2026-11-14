import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/call_modes/domain/call_mode.dart';
import 'package:voicemail/features/call_modes/presentation/controllers/modes_controller.dart';
import 'package:voicemail/features/call_modes/presentation/screens/call_modes_screen.dart';
import 'package:voicemail/features/greetings/domain/greeting_preset.dart';
import 'package:voicemail/features/greetings/presentation/controllers/greetings_controller.dart';
import 'package:voicemail/features/greetings/presentation/screens/greetings_screen.dart';

void main() {
  group('CallHandlingMode & DND Logic Tests', () {
    test('All 4 CallHandlingMode values have titles, subtitles, and credit descriptions', () {
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
  });

  group('GreetingsPreset & Controller Tests', () {
    test('Default presets include In Class (Danish K), Meeting, Hindi, and Malayalam', () {
      final presets = GreetingPreset.defaultPresets;
      expect(presets.length, greaterThanOrEqualTo(5));

      final hasClass = presets.any((p) => p.title.contains('Class'));
      final hasMeeting = presets.any((p) => p.title.contains('Meeting'));
      final hasHindi = presets.any((p) => p.language == 'Hindi');
      final hasMalayalam = presets.any((p) => p.language == 'Malayalam');

      expect(hasClass, isTrue);
      expect(hasMeeting, isTrue);
      expect(hasHindi, isTrue);
      expect(hasMalayalam, isTrue);
    });

    test('GreetingsController updates text, language, and contact group', () {
      final controller = GreetingsController();
      controller.updateText('Hello world');
      expect(controller.state.activeGreeting.text, 'Hello world');

      controller.setLanguage('Malayalam');
      expect(controller.state.selectedLanguage, 'Malayalam');

      controller.setGroup('Work & Clients');
      expect(controller.state.selectedGroup, 'Work & Clients');
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
      await tester.pumpWidget(buildTestableWidget(const CallModesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Call Handling & DND'), findsOneWidget);
      expect(find.text('Server Greeting Mode Active'), findsOneWidget);

      // Verify mode cards
      expect(find.text('Server Greeting Mode'), findsOneWidget);
      expect(find.text('Auto-Decline with Message'), findsOneWidget);
      expect(find.text('Auto-Answer Assistant'), findsOneWidget);
      expect(find.text('Silent DND Mode'), findsOneWidget);

      // Verify locked emergency services
      expect(find.textContaining('Emergency Numbers (112, 100, 108, 101)'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
    });

    testWidgets('GreetingsScreen renders active greeting card, presets, variable chips, and language picker', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const GreetingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Custom Greetings Hub'), findsOneWidget);
      expect(find.text('Listen to Preview (TTS)'), findsOneWidget);
      expect(find.text('{name}'), findsOneWidget);
      expect(find.text('{caller}'), findsOneWidget);
      expect(find.text('{time_back}'), findsOneWidget);
      expect(find.text('Save Greeting on Device'), findsOneWidget);
    });
  });
}

