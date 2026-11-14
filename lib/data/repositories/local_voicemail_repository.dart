import 'package:voicemail/core/database/local_database.dart';
import 'package:voicemail/core/errors/app_failure.dart';
import 'package:voicemail/core/result/result.dart';
import 'package:voicemail/domain/repositories/voicemail_repository.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';

class LocalVoicemailRepository implements VoicemailRepository {
  final LocalDatabase _database;

  LocalVoicemailRepository({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  @override
  Future<Result<List<Voicemail>, AppFailure>> getVoicemails({String? query}) async {
    try {
      final list = await _database.getAllVoicemails(searchQuery: query);
      return Success(list);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load voicemails: $e'));
    }
  }

  @override
  Future<Result<Voicemail?, AppFailure>> getVoicemailById(String id) async {
    try {
      final item = await _database.getVoicemailById(id);
      return Success(item);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to get voicemail: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> markAsRead(String id, bool isRead) async {
    try {
      await _database.markAsRead(id, isRead);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to mark read: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> toggleStarred(String id, bool isStarred) async {
    try {
      await _database.toggleStarred(id, isStarred);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to toggle star: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteVoicemail(String id) async {
    try {
      await _database.deleteVoicemail(id);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete voicemail: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteMultiple(Set<String> ids) async {
    try {
      await _database.deleteMultiple(ids);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete voicemails: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> markMultipleAsRead(Set<String> ids, bool isRead) async {
    try {
      await _database.markMultipleAsRead(ids, isRead);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to mark voicemails as read: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> insertVoicemail(Voicemail vm) async {
    try {
      await _database.insertVoicemail(vm);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to insert voicemail: $e'));
    }
  }
}
