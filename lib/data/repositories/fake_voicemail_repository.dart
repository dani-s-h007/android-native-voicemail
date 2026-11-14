import 'package:voicemail/core/errors/app_failure.dart';
import 'package:voicemail/core/result/result.dart';
import 'package:voicemail/domain/repositories/voicemail_repository.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';

/// In-memory mock voicemail repository for standalone preview, tests, and demo mode.
class FakeVoicemailRepository implements VoicemailRepository {
  final List<Voicemail> _items;

  FakeVoicemailRepository({List<Voicemail>? initialItems})
      : _items = initialItems ??
            [
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

  @override
  Future<Result<List<Voicemail>, AppFailure>> getVoicemails({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      return Success(List.unmodifiable(_items));
    }
    final q = query.trim().toLowerCase();
    final filtered = _items.where((v) {
      final nameMatch = v.callerName?.toLowerCase().contains(q) ?? false;
      final numMatch = v.callerNumber.toLowerCase().contains(q);
      final transcriptMatch = v.transcriptText?.toLowerCase().contains(q) ?? false;
      return nameMatch || numMatch || transcriptMatch;
    }).toList();
    return Success(filtered);
  }

  @override
  Future<Result<Voicemail?, AppFailure>> getVoicemailById(String id) async {
    try {
      final item = _items.firstWhere((v) => v.id == id);
      return Success(item);
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<void, AppFailure>> markAsRead(String id, bool isRead) async {
    final idx = _items.indexWhere((v) => v.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: isRead);
    }
    return const Success(null);
  }

  @override
  Future<Result<void, AppFailure>> toggleStarred(String id, bool isStarred) async {
    final idx = _items.indexWhere((v) => v.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isStarred: isStarred);
    }
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
    for (final id in ids) {
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
