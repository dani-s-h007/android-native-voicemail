import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/diagnostics/presentation/screens/call_diagnostics_screen.dart';
import 'package:voicemail/features/reliability/presentation/screens/reliability_check_screen.dart';
import 'package:voicemail/features/settings/presentation/screens/region_carrier_screen.dart';
import 'package:voicemail/features/settings/presentation/settings_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  group('Stage 6: Reliability & Diagnostics Tests', () {
    testWidgets('ReliabilityCheckScreen renders health score banner and system check items', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const ReliabilityCheckScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Reliability & Device Health'), findsOneWidget);
      expect(find.text('SYSTEM PERMISSIONS & EXEMPTIONS'), findsOneWidget);
      expect(find.text('Call Screening Service'), findsOneWidget);
      expect(find.text('Battery Optimization Exemption'), findsOneWidget);
      expect(find.text('Call Forwarding Protection'), findsOneWidget);
      expect(find.text('Background Watchdog Service'), findsOneWidget);
    });

    testWidgets('CallDiagnosticsScreen renders decision audit trail and search filter', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const CallDiagnosticsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Why Did This Call Not Work?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify decision trail items
      expect(find.text('DISMISSED_TO_VOICEMAIL'), findsOneWidget);
      expect(find.text('SCREENED_BY_DND'), findsOneWidget);
      expect(find.text('EMERGENCY_BYPASS_ALLOWED'), findsOneWidget);

      // Test searching in decision trail
      await tester.enterText(find.byType(TextField), 'EMERGENCY');
      await tester.pumpAndSettle();

      expect(find.text('EMERGENCY_BYPASS_ALLOWED'), findsOneWidget);
      expect(find.text('SCREENED_BY_DND'), findsNothing);
    });
  });

  group('Stage 6: Region & Carrier Screen Tests', () {
    testWidgets('RegionCarrierScreen renders country selector, locked emergency banner, and MMI controls', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const RegionCarrierScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Region & Carrier Settings'), findsOneWidget);
      expect(find.text('DEFAULT REGION & RULES'), findsOneWidget);
      expect(find.text('MOBILE CARRIER PROFILE'), findsOneWidget);
      expect(find.text('Emergency Numbers'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('Save & Apply Telephony Profile'), findsOneWidget);
    });
  });

  group('Stage 6: Settings Screen Tests', () {
    testWidgets('SettingsScreen renders account, notifications, appearance, retention, and local backup', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text(AppConfig.appName), findsWidgets);

      // Verify sections
      expect(find.text('USER ACCOUNT & PROFILE'), findsOneWidget);
      expect(find.text('REGION & CARRIER'), findsOneWidget);
      expect(find.text('NOTIFICATIONS & SOUNDS'), findsOneWidget);
      expect(find.text('APPEARANCE & THEME'), findsOneWidget);
      expect(find.text('APPLICATION LANGUAGE'), findsOneWidget);
      expect(find.text('PRIVACY & LOCAL DATA (ZERO CLOUD)'), findsOneWidget);
      expect(find.text('BACKUP & RESTORE'), findsOneWidget);
      expect(find.text('SYSTEM HEALTH & DIAGNOSTICS'), findsOneWidget);
      expect(find.text('HELP & ABOUT'), findsOneWidget);

      // Verify specific items
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Primary Phone Number'), findsOneWidget);
      expect(find.text('Default Region & Carrier Profile'), findsOneWidget);
      expect(find.text('Emergency Numbers (Locked)'), findsOneWidget);
      expect(find.text('Audio Retention Period'), findsOneWidget);
      expect(find.text('Block Screen Capture'), findsOneWidget);
      expect(find.text('Export Local Backup'), findsOneWidget);
    });

    testWidgets('SettingsScreen allows editing user display name via dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);

      await tester.tap(find.text('Display Name'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Display Name'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Taylor Reed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Taylor Reed'), findsOneWidget);
    });
  });
}
