import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/data/repositories/fake_voicemail_repository.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';
import 'package:voicemail/features/voicemail/presentation/controllers/voicemail_controller.dart';
import 'package:voicemail/features/voicemail/presentation/screens/voicemail_detail_screen.dart';
import 'package:voicemail/features/voicemail/presentation/screens/voicemail_inbox_screen.dart';

void main() {
  final sampleTestItems = [
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

  group('VoicemailRepository & Controller Unit Tests', () {
    late FakeVoicemailRepository repo;

    setUp(() {
      repo = FakeVoicemailRepository(initialItems: sampleTestItems);
    });

    test('default FakeVoicemailRepository starts completely empty with zero dummy data', () async {
      final cleanRepo = FakeVoicemailRepository();
      final res = await cleanRepo.getVoicemails();
      expect(res.isSuccess, isTrue);
      expect(res.orNull?.isEmpty, isTrue);
    });

    test('getVoicemails returns items', () async {
      final res = await repo.getVoicemails();
      expect(res.isSuccess, isTrue);
      expect(res.orNull?.length, 2);
    });

    test('search query filters by name, number, and transcript', () async {
      final resName = await repo.getVoicemails(query: 'Alex');
      expect(resName.orNull?.any((v) => v.callerName == 'Alex Morgan'), isTrue);

      final resNumber = await repo.getVoicemails(query: '019');
      expect(resNumber.orNull?.isNotEmpty, isTrue);

      final resTranscript = await repo.getVoicemails(query: 'proposal');
      expect(resTranscript.orNull?.isNotEmpty, isTrue);
    });

    test('markAsRead and toggleStarred update item states', () async {
      await repo.markAsRead('vm_001', true);
      final vm1 = (await repo.getVoicemailById('vm_001')).orNull;
      expect(vm1?.isRead, isTrue);

      await repo.toggleStarred('vm_002', false);
      final vm2 = (await repo.getVoicemailById('vm_002')).orNull;
      expect(vm2?.isStarred, isFalse);
    });

    test('deleteVoicemail and deleteMultiple remove entries from repository', () async {
      await repo.deleteVoicemail('vm_002');
      final res1 = await repo.getVoicemails();
      expect(res1.orNull?.length, 1);

      await repo.deleteMultiple({'vm_001'});
      final res2 = await repo.getVoicemails();
      expect(res2.orNull?.isEmpty, isTrue);
    });
  });

  group('Voicemail Inbox & Detail Widget Tests', () {
    Widget buildTestableWidget(Widget child, {FakeVoicemailRepository? repository}) {
      final testRepo = repository ?? FakeVoicemailRepository(initialItems: sampleTestItems);
      return ProviderScope(
        overrides: [
          voicemailRepositoryProvider.overrideWithValue(testRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: child,
        ),
      );
    }

    testWidgets('VoicemailInboxScreen renders clean Inbox Zero empty state when no voicemails exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(
        const VoicemailInboxScreen(),
        repository: FakeVoicemailRepository(), // completely clean empty repository
      ));
      await tester.pumpAndSettle();

      expect(find.text('Inbox Zero'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsNothing);
    });

    testWidgets('VoicemailInboxScreen renders list, search bar, and filter chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const VoicemailInboxScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Voicemail'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Starred'), findsOneWidget);

      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Taylor Reed'), findsOneWidget);
    });

    testWidgets('VoicemailInboxScreen supports multi-selection and select all', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const VoicemailInboxScreen()));
      await tester.pumpAndSettle();

      // Long press first item to enter multi-select mode
      await tester.longPress(find.text('Alex Morgan'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.select_all), findsOneWidget);

      // Tap select all
      await tester.tap(find.byIcon(Icons.select_all));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);

      // Cancel selection
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Voicemail'), findsOneWidget);
    });

    testWidgets('VoicemailDetailScreen renders audio scrubber, controls, actions, and transcript',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const VoicemailDetailScreen(voicemailId: 'vm_001'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('+1 (555) 019-2834'), findsOneWidget);
      expect(find.text('Call Back'), findsOneWidget);
      expect(find.text('SMS / Chat'), findsOneWidget);
      expect(find.text('Add Contact'), findsOneWidget);
      expect(find.text('Block Caller'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('Interactive Transcript'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);

      // Tap Play button to start audio playback
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Tap Pause button
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('VoicemailDetailScreen displays error state when ID is not found', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VoicemailDetailScreen(voicemailId: 'non_existent_id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This voicemail could not be found or was deleted.'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });
  });
}
