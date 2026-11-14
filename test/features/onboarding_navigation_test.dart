import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/app/di/service_providers.dart';
import 'package:voicemail/data/services/fake_permission_service.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/onboarding/presentation/screens/consent_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/permission_rationale_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/setup_wizard_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/splash_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child, {FakePermissionService? permissionService}) {
    return ProviderScope(
      overrides: [
        if (permissionService != null)
          permissionServiceProvider.overrideWithValue(permissionService),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  group('Stage 3: Onboarding & Navigation Widget Tests', () {
    testWidgets('SplashScreen renders app name and branding tagline', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppConfig.appName), findsOneWidget);
      expect(find.text(AppConfig.appTagline), findsOneWidget);
      expect(find.text('Universal Call Assistant'), findsOneWidget);

      // Drain navigation timer to prevent pending timer error
      await tester.pump(const Duration(milliseconds: 1400));
    });

    testWidgets('OnboardingScreen displays 3 benefit slides and navigates with Next', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Slide 1: 100% On-Device Privacy
      expect(find.text('100% On-Device Privacy'), findsOneWidget);
      expect(find.text('Zero Permanent Cloud Storage'), findsOneWidget);

      // Tap Next to navigate to Slide 2
      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Slide 2: Universal Carrier Support
      expect(find.text('Universal Carrier Support'), findsOneWidget);
      expect(find.text('Works With Any Mobile Network'), findsOneWidget);

      // Tap Next to navigate to Slide 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Slide 3: Intelligent Call Assistant
      expect(find.text('Intelligent Call Assistant'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('ConsentScreen requires checkboxes before enabling Agree button', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ConsentScreen()));
      await tester.pumpAndSettle();

      final agreeButton = find.widgetWithText(FilledButton, 'Agree & Continue');
      expect(agreeButton, findsOneWidget);

      // Initially disabled
      FilledButton buttonWidget = tester.widget(agreeButton);
      expect(buttonWidget.onPressed, isNull);

      // Tap first checkbox (Terms)
      final termsTile = find.byType(CheckboxListTile).first;
      await tester.tap(termsTile);
      await tester.pumpAndSettle();

      buttonWidget = tester.widget(agreeButton);
      expect(buttonWidget.onPressed, isNull); // Still disabled

      // Tap second checkbox (Recording notice)
      final recordingTile = find.byType(CheckboxListTile).last;
      await tester.tap(recordingTile);
      await tester.pumpAndSettle();

      // Now enabled
      buttonWidget = tester.widget(agreeButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('PermissionRationaleScreen renders permission rationale cards and handles grant', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakePermissions = FakePermissionService();

      await tester.pumpWidget(
        buildTestableWidget(
          const PermissionRationaleScreen(),
          permissionService: fakePermissions,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permissions & System Access'), findsOneWidget);
      expect(find.text('Call Screening Service'), findsOneWidget);
      expect(find.text('Phone & Call State'), findsOneWidget);
      expect(find.text('Microphone & Audio'), findsOneWidget);
      expect(find.text('Contacts (Recommended)'), findsOneWidget);
      expect(find.text('Battery Optimization Exemption'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Tap Set Role button on Call Screening
      final setRoleFinder = find.widgetWithText(FilledButton, 'Set Role');
      expect(setRoleFinder, findsOneWidget);
      await tester.tap(setRoleFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('SetupWizardScreen guides user through 4 configuration steps', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const SetupWizardScreen()));
      await tester.pumpAndSettle();

      // Step 1: Select Country / Region
      expect(find.text('Select Your Country / Region'), findsOneWidget);
      expect(find.text('Locked Emergency Numbers'), findsOneWidget);

      // Tap step 2 header
      await tester.tap(find.text('Select Carrier or Custom Codes'));
      await tester.pumpAndSettle();

      // Step 2 is active
      expect(find.text('Carrier Network Profile'), findsOneWidget);

      // Tap step 3 header
      await tester.tap(find.text('Forwarding Number & Activation'));
      await tester.pumpAndSettle();

      // Step 3 is active
      expect(find.text('Open Phone App Call Settings'), findsOneWidget);

      // Tap step 4 header
      await tester.tap(find.text('Test Call Verification'));
      await tester.pumpAndSettle();

      // Step 4 is active
      expect(find.text('Active Spoken Greeting Preview'), findsOneWidget);
      expect(find.text('Simulate Test Call Verification'), findsOneWidget);

      // Tap simulate test call
      await tester.tap(find.text('Simulate Test Call Verification'));
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Complete & Open Inbox'), findsWidgets);
    });
  });
}
