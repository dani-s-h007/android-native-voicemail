import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/about/presentation/screens/about_screen.dart';
import 'package:voicemail/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:voicemail/features/legal/domain/legal_document.dart';
import 'package:voicemail/features/legal/presentation/screens/legal_hub_screen.dart';
import 'package:voicemail/l10n/app_localizations.dart';

void main() {
  group('Localization Unit Tests', () {
    test('AppLocalizations translates key terms across en, hi, ml', () {
      const locEn = AppLocalizations(Locale('en'));
      expect(locEn.appName, 'Vani Voicemail');
      expect(locEn.tabVoicemail, 'Voicemail');
      expect(locEn.tabModes, 'Modes');

      const locHi = AppLocalizations(Locale('hi'));
      expect(locHi.appName, 'वाणी वॉयसमेल');
      expect(locHi.tabVoicemail, 'वॉयसमेल');

      const locMl = AppLocalizations(Locale('ml'));
      expect(locMl.appName, 'വാണി വോയ്സ്മെയിൽ');
      expect(locMl.tabVoicemail, 'വോയ്സ്മെയിൽ');
    });

    test('LegalDocType contains all 7 mandatory documents', () {
      expect(LegalDocType.values.length, 7);
      final paths = LegalDocType.values.map((d) => d.assetPath).toList();
      expect(paths, contains('assets/legal/privacy_policy.md'));
      expect(paths, contains('assets/legal/terms_of_service.md'));
      expect(paths, contains('assets/legal/data_safety.md'));
      expect(paths, contains('assets/legal/call_recording_notice.md'));
      expect(paths, contains('assets/legal/permissions_explanation.md'));
      expect(paths, contains('assets/legal/disclaimer.md'));
      expect(paths, contains('assets/legal/grievance_officer.md'));
    });
  });

  group('About, Legal Hub & Feedback Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: child,
        ),
      );
    }

    testWidgets('AboutScreen renders developer profile, portfolio, and changelog', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About Vani Voicemail'), findsOneWidget);
      expect(find.text('Danish K'), findsOneWidget);
      expect(find.text('Visit Portfolio: danishk.web.app'), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
      expect(find.text('CHANGELOG • V1.0.0 (INITIAL RELEASE)'), findsOneWidget);
    });

    testWidgets('LegalHubScreen renders all 7 compliance document cards', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LegalHubScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Legal & Compliance Hub'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Google Play Data Safety'), findsOneWidget);
      expect(find.text('Call Recording & Consent Notice'), findsOneWidget);
      expect(find.text('Permissions Explanation'), findsOneWidget);
      expect(find.text('Legal Disclaimer'), findsOneWidget);
      expect(find.text('Grievance Officer Contact'), findsOneWidget);
    });

    testWidgets('FeedbackScreen renders topic selector, text input, and rating card', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const FeedbackScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Feedback & Support'), findsOneWidget);
      expect(find.text('Enjoying Vani Voicemail?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Attach Redacted Diagnostic Log'), findsOneWidget);
      expect(find.text('Send Feedback to Developer'), findsOneWidget);
    });
  });
}

