import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/diagnostics/presentation/screens/call_diagnostics_screen.dart';
import 'package:voicemail/features/reliability/presentation/screens/reliability_check_screen.dart';
import 'package:voicemail/features/settings/presentation/settings_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  group('Stage 6: Reliability, Diagnostics & Settings Tests', () {
    testWidgets('ReliabilityCheckScreen renders health score banner and system check items', (tester) async {
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
      await tester.pumpWidget(buildTestableWidget(const CallDiagnosticsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Why Did This Call Not Work?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify decision trail items
      expect(find.text('DISMISSED_TO_VOICEMAIL'), findsOneWidget);
      expect(find.text('SCREENED_BY_DND'), findsOneWidget);
      expect(find.text('EMERGENCY_BYPASS_ALLOWED'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders identity, theme controls, retention, and local backup', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Vani Voicemail'), findsOneWidget);
      expect(find.textContaining('+914954268791'), findsOneWidget);
      expect(find.textContaining('danishk.web.app'), findsOneWidget);

      // Verify sections
      expect(find.text('APPEARANCE & THEME'), findsOneWidget);
      expect(find.text('CARRIER & FORWARDING'), findsOneWidget);
      expect(find.text('PRIVACY & LOCAL DATA (ZERO CLOUD)'), findsOneWidget);
      expect(find.text('BACKUP & LOCAL EXPORT'), findsOneWidget);
      expect(find.text('SYSTEM HEALTH & DIAGNOSTICS'), findsOneWidget);
    });
  });
}

