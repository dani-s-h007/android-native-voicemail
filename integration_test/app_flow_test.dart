import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/app.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/app/config/flavor_config.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/data/repositories/fake_voicemail_repository.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';
import 'package:voicemail/features/voicemail/presentation/controllers/voicemail_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingComplete: true,
      AppConstants.keyConsentAccepted: true,
      'setup_wizard_completed': true,
      AppConstants.keyForwardingActive: true,
    });

    FlavorConfig.initialize(
      config: const FlavorConfig(
        flavor: Flavor.dev,
        appTitle: AppConfig.appName,
        applicationId: AppConfig.packageIdDev,
        enableDebugLogging: true,
        mockServicesByDefault: true,
      ),
    );
  });

  testWidgets(
      'Complete End-to-End Flow: App Launch -> Inbox -> Detail -> Playback -> Navigation Shell',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final sampleItems = [
      Voicemail(
        id: 'vm_001',
        callerNumber: '+1 (555) 019-2834',
        callerName: 'Alex Morgan',
        audioLocalPath: 'audio/sample_001.m4a',
        durationSeconds: 24,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Hello, this is Alex following up on the project proposal. Give me a call back when you get a chance.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),
      Voicemail(
        id: 'vm_002',
        callerNumber: '+1 (555) 012-7890',
        callerName: 'Taylor Reed',
        audioLocalPath: 'audio/sample_002.m4a',
        durationSeconds: 18,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
        isStarred: true,
        transcriptText:
            'Hi there, just wanted to check if you received the documentation sent earlier today.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Auto-Declined',
      ),
    ];
    final mockRepo = FakeVoicemailRepository(initialItems: sampleItems);

    // 1. Launch App with mock repository override
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voicemailRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const CallAssistantApp(isOnboardingCompleted: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    // 2. Verify Inbox Loaded with Seed Voicemails
    expect(find.text('Voicemail'), findsWidgets);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('Taylor Reed'), findsOneWidget);

    // 3. Test Filter Chips
    final unreadChip = find.text('Unread');
    expect(unreadChip, findsOneWidget);
    await tester.tap(unreadChip);
    await tester.pumpAndSettle();

    final allChip = find.text('All');
    expect(allChip, findsOneWidget);
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    // 4. Tap on First Voicemail (Alex Morgan) to open Detail Screen
    final firstItem = find.text('Alex Morgan');
    expect(firstItem, findsOneWidget);
    await tester.tap(firstItem);
    await tester.pumpAndSettle();

    // 5. Verify Detail Screen Components
    expect(find.text('Voicemail Details'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('+1 (555) 019-2834'), findsOneWidget);
    expect(find.text('Interactive Transcript'), findsOneWidget);

    // 6. Test Audio Controls: Tap Play / Pause FAB
    final playFab = find.byType(FloatingActionButton);
    expect(playFab, findsOneWidget);
    await tester.tap(playFab);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify pause icon appears during active playback
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(playFab);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // 7. Test Copy Transcript
    final copyButton = find.text('Copy Text');
    expect(copyButton, findsOneWidget);
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    // 8. Go back to Inbox
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(find.text('Voicemail'), findsWidgets);
    }

    // 9. Test Navigation Shell: Switch to Modes Tab
    final modesTab = find.byIcon(Icons.tune_rounded);
    if (modesTab.evaluate().isNotEmpty) {
      await tester.tap(modesTab);
      await tester.pumpAndSettle();
      expect(find.text('Call Handling Modes'), findsOneWidget);
    }

    // 10. Switch to Greetings Tab
    final greetingsTab = find.byIcon(Icons.record_voice_over_rounded);
    if (greetingsTab.evaluate().isNotEmpty) {
      await tester.tap(greetingsTab);
      await tester.pumpAndSettle();
      expect(find.text('Greetings Studio'), findsOneWidget);
    }

    // 11. Switch to Settings Tab
    final settingsTab = find.byIcon(Icons.settings_rounded);
    if (settingsTab.evaluate().isNotEmpty) {
      await tester.tap(settingsTab);
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Region & Carrier'), findsOneWidget);
    }
  });
}
