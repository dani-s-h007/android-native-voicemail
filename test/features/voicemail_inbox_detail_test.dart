import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/core/errors/app_failure.dart';
import 'package:voicemail/core/result/result.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';
import 'package:voicemail/domain/repositories/voicemail_repository.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';
import 'package:voicemail/features/voicemail/presentation/controllers/voicemail_controller.dart';
import 'package:voicemail/features/voicemail/presentation/screens/voicemail_detail_screen.dart';
import 'package:voicemail/features/voicemail/presentation/screens/voicemail_inbox_screen.dart';

class TestVoicemailRepository implements VoicemailRepository {
  final List<Voicemail> _items = [
    Voicemail(
      id: 'vm_001',
      callerNumber: '+919845012345',
      callerName: 'Ramesh Nair',
      audioLocalPath: 'test_audio_001.m4a',
      durationSeconds: 24,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      isStarred: false,
      transcriptText: 'Hi Danish, Ramesh here regarding the college schedule.',
      detectedLanguage: 'English',
      transcriptionStatus: 'completed',
    ),
    Voicemail(
      id: 'vm_002',
      callerNumber: '+919447198765',
      callerName: 'Dr. Priya Menon',
      audioLocalPath: 'test_audio_002.m4a',
      durationSeconds: 18,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      isStarred: false,
      transcriptText: 'Hello Danish, please call back when you are free.',
      detectedLanguage: 'English',
      transcriptionStatus: 'completed',
    ),
  ];

  @override
  Future<Result<List<Voicemail>, AppFailure>> getVoicemails({String? query}) async {
    if (query == null || query.isEmpty) return Success(List.unmodifiable(_items));
    final q = query.toLowerCase();
    return Success(_items.where((v) =>
        (v.callerName?.toLowerCase().contains(q) ?? false) ||
        v.callerNumber.contains(q) ||
        (v.transcriptText?.toLowerCase().contains(q) ?? false)).toList());
  }

  @override
  Future<Result<Voicemail?, AppFailure>> getVoicemailById(String id) async {
    final item = _items.cast<Voicemail?>().firstWhere((v) => v?.id == id, orElse: () => null);
    return Success(item);
  }

  @override
  Future<Result<void, AppFailure>> markAsRead(String id, bool isRead) async {
    final idx = _items.indexWhere((v) => v.id == id);
    if (idx != -1) _items[idx] = _items[idx].copyWith(isRead: isRead);
    return const Success(null);
  }

  @override
  Future<Result<void, AppFailure>> toggleStarred(String id, bool isStarred) async {
    final idx = _items.indexWhere((v) => v.id == id);
    if (idx != -1) _items[idx] = _items[idx].copyWith(isStarred: isStarred);
    return const Success(null);
  }

  @override
  Future<Result<void, AppFailure>> deleteVoicemail(String id) async {
    _items.removeWhere((v) => v.id == id);
    return const Success(null);
  }

  @override
  Future<Result<void, AppFailure>> deleteMultiple(Set<String> ids) async {
    _items.removeWhere((v) => ids.contains(v.id));
    return const Success(null);
  }

  @override
  Future<Result<void, AppFailure>> markMultipleAsRead(Set<String> ids, bool isRead) async {
    for (var id in ids) {
      await markAsRead(id, isRead);
    }
    return const Success(null);
  }

  @override
  Future<Result<void, AppFailure>> insertVoicemail(Voicemail vm) async {
    _items.insert(0, vm);
    return const Success(null);
  }
}

void main() {
  group('VoicemailRepository Unit Tests', () {
    late TestVoicemailRepository repo;

    setUp(() {
      repo = TestVoicemailRepository();
    });

    test('getVoicemails returns items', () async {
      final res = await repo.getVoicemails();
      expect(res.isSuccess, isTrue);
      expect(res.orNull?.length, 2);
    });

    test('search query filters by name and number', () async {
      final resName = await repo.getVoicemails(query: 'Ramesh');
      expect(resName.orNull?.any((v) => v.callerName == 'Ramesh Nair'), isTrue);

      final resNumber = await repo.getVoicemails(query: '98450');
      expect(resNumber.orNull?.isNotEmpty, isTrue);
    });

    test('markAsRead and toggleStarred update item states', () async {
      await repo.markAsRead('vm_001', true);
      final vm1 = (await repo.getVoicemailById('vm_001')).orNull;
      expect(vm1?.isRead, isTrue);

      await repo.toggleStarred('vm_002', true);
      final vm2 = (await repo.getVoicemailById('vm_002')).orNull;
      expect(vm2?.isStarred, isTrue);
    });

    test('deleteVoicemail removes entry from repository', () async {
      await repo.deleteVoicemail('vm_002');
      final res = await repo.getVoicemails();
      expect(res.orNull?.length, 1);
    });
  });

  group('Voicemail Inbox & Detail Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      final testRepo = TestVoicemailRepository();
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

    testWidgets('VoicemailInboxScreen renders list, search bar, and filter chips', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const VoicemailInboxScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Voicemail'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Starred'), findsOneWidget);

      expect(find.text('Ramesh Nair'), findsOneWidget);
    });

    testWidgets('VoicemailDetailScreen renders audio scrubber, controls, and transcript', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const VoicemailDetailScreen(voicemailId: 'vm_001'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ramesh Nair'), findsOneWidget);
      expect(find.text('+919845012345'), findsOneWidget);
      expect(find.text('Call Back'), findsOneWidget);
      expect(find.text('SMS / Chat'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('Interactive Transcript'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });
  });
}
