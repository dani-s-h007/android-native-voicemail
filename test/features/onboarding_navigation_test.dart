import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/onboarding/presentation/screens/consent_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/permission_rationale_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/splash_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  group('Stage 3: Onboarding & Navigation Widget Tests', () {
    testWidgets('SplashScreen renders app name and Danish K creator credit', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Vani Voicemail'), findsOneWidget);
      expect(find.textContaining('Created by Danish K'), findsOneWidget);
    });

    testWidgets('OnboardingScreen displays 3 benefit slides and navigates with Next', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Slide 1
      expect(find.text('100% On-Device Privacy'), findsOneWidget);
      expect(find.text('Zero Permanent Cloud Storage'), findsOneWidget);

      // Tap Next to navigate to Slide 2
      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Slide 2
      expect(find.text('Tailored for India'), findsOneWidget);
      expect(find.text('Seamless Jio & Airtel Integration'), findsOneWidget);
    });

    testWidgets('ConsentScreen requires checkboxes before enabling Agree button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ConsentScreen()));
      await tester.pumpAndSettle();

      final agreeButton = find.widgetWithText(FilledButton, 'Agree & Continue');
      expect(agreeButton, findsOneWidget);

      // Initially disabled
      FilledButton buttonWidget = tester.widget(agreeButton);
      expect(buttonWidget.onPressed, isNull);

      // Tap first checkbox
      final termsTile = find.byType(CheckboxListTile).first;
      await tester.tap(termsTile);
      await tester.pumpAndSettle();

      buttonWidget = tester.widget(agreeButton);
      expect(buttonWidget.onPressed, isNull); // Still disabled (needs 2nd)

      // Tap second checkbox
      final recordingTile = find.byType(CheckboxListTile).last;
      await tester.tap(recordingTile);
      await tester.pumpAndSettle();

      // Now enabled
      buttonWidget = tester.widget(agreeButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('PermissionRationaleScreen renders permission rationale cards', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const PermissionRationaleScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Permissions & System Access'), findsOneWidget);
      expect(find.text('Call Screening Service'), findsOneWidget);
      expect(find.text('Phone & Call State'), findsOneWidget);
      expect(find.text('Battery Optimization Exemption'), findsOneWidget);
    });
  });
}

