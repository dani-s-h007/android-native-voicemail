import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/app.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/app/config/flavor_config.dart';
import 'package:voicemail/core/constants/app_constants.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingComplete: true,
      AppConstants.keyConsentAccepted: true,
    });

    FlavorConfig.initialize(
      config: const FlavorConfig(
        flavor: Flavor.dev,
        appTitle: AppConfig.appName,
        applicationId: 'com.dalsc.voicemail_assistant',
        enableDebugLogging: true,
        mockServicesByDefault: true,
      ),
    );
  });

  testWidgets('Complete End-to-End Flow: App Launch -> Inbox -> Detail -> Playback', (tester) async {
    // 1. Launch App
    await tester.pumpWidget(
      const ProviderScope(
        child: VaniVoicemailApp(isOnboardingCompleted: true),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Verify Inbox Loaded with Seed Voicemails
    expect(find.text('Voicemail'), findsOneWidget);
    expect(find.text('Ramesh Nair'), findsOneWidget);

    // 3. Test Filter Chips
    final unreadChip = find.text('Unread');
    expect(unreadChip, findsOneWidget);
    await tester.tap(unreadChip);
    await tester.pumpAndSettle();

    final allChip = find.text('All');
    expect(allChip, findsOneWidget);
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    // 4. Tap on First Voicemail (Ramesh Nair) to open Detail Screen
    final firstItem = find.text('Ramesh Nair');
    expect(firstItem, findsOneWidget);
    await tester.tap(firstItem);
    await tester.pumpAndSettle();

    // 5. Verify Detail Screen Components
    expect(find.text('Voicemail Details'), findsOneWidget);
    expect(find.text('Ramesh Nair'), findsOneWidget);
    expect(find.text('+919845012345'), findsOneWidget);
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
      expect(find.text('Voicemail'), findsOneWidget);
    }
  });
}

