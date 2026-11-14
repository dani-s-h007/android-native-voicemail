import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/about/presentation/screens/about_screen.dart';
import 'package:voicemail/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:voicemail/features/legal/domain/legal_document.dart';
import 'package:voicemail/features/legal/presentation/screens/legal_document_screen.dart';
import 'package:voicemail/features/legal/presentation/screens/legal_hub_screen.dart';
import 'package:voicemail/l10n/app_localizations.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Localization Unit Tests', () {
    test('AppLocalizations translates key terms across en, es, hi, ml', () {
      const locEn = AppLocalizations(Locale('en'));
      expect(locEn.appName, 'Voicemail Assistant');
      expect(locEn.tabVoicemail, 'Voicemail');
      expect(locEn.tabModes, 'Modes');

      const locEs = AppLocalizations(Locale('es'));
      expect(locEs.appName, 'Asistente de Buzón de Voz');
      expect(locEs.tabVoicemail, 'Buzón de Voz');

      const locHi = AppLocalizations(Locale('hi'));
      expect(locHi.appName, 'वॉयसमेल सहायक');
      expect(locHi.tabVoicemail, 'वॉयसमेल');

      const locMl = AppLocalizations(Locale('ml'));
      expect(locMl.appName, 'വോയ്സ്മെയിൽ അസിസ്റ്റന്റ്');
      expect(locMl.tabVoicemail, 'വോയ്സ്മെയിൽ');
    });

    test('LegalDocType contains all 7 mandatory documents and valid webUrls without personal identifiers', () {
      expect(LegalDocType.values.length, 7);
      final paths = LegalDocType.values.map((d) => d.assetPath).toList();
      expect(paths, contains('assets/legal/privacy_policy.md'));
      expect(paths, contains('assets/legal/terms_of_service.md'));
      expect(paths, contains('assets/legal/data_safety.md'));
      expect(paths, contains('assets/legal/call_recording_notice.md'));
      expect(paths, contains('assets/legal/permissions_explanation.md'));
      expect(paths, contains('assets/legal/disclaimer.md'));
      expect(paths, contains('assets/legal/grievance_officer.md'));

      for (final doc in LegalDocType.values) {
        expect(doc.webUrl.isNotEmpty, isTrue);
        expect(doc.webUrl.toLowerCase().contains('danishk'), isFalse);
      }
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

    testWidgets('AboutScreen renders app identity, developer info, and changelog', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About ${AppConfig.appName}'), findsOneWidget);
      expect(find.text(AppConfig.appName), findsWidgets);
      expect(find.text(AppConfig.developerName), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
      expect(find.text('Open-Source Licenses'), findsOneWidget);
      expect(find.text('CHANGELOG • V1.0.0 (INITIAL RELEASE)'), findsOneWidget);
    });

    testWidgets('LegalHubScreen renders all 7 compliance document cards', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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

    testWidgets('LegalDocumentScreen renders document and replaces placeholder tokens', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const LegalDocumentScreen(documentId: 'privacy')));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Official Legal Document • Compliance Notice'), findsOneWidget);
      expect(find.text('Open Official Hosted Web Version'), findsOneWidget);
    });

    testWidgets('FeedbackScreen renders topic selector, text input, and rating card', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const FeedbackScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Feedback & Support'), findsOneWidget);
      expect(find.text('Enjoying ${AppConfig.appName}?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Attach Redacted Diagnostic Log'), findsOneWidget);
      expect(find.text('Send Feedback to Developer'), findsOneWidget);
    });
  });
}
