import 'package:voicemail/core/result/result.dart';
import 'package:voicemail/core/errors/app_failure.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';

abstract class VoicemailRepository {
  Future<Result<List<Voicemail>, AppFailure>> getVoicemails({String? query});
  Future<Result<Voicemail?, AppFailure>> getVoicemailById(String id);
  Future<Result<void, AppFailure>> markAsRead(String id, bool isRead);
  Future<Result<void, AppFailure>> toggleStarred(String id, bool isStarred);
  Future<Result<void, AppFailure>> deleteVoicemail(String id);
  Future<Result<void, AppFailure>> deleteMultiple(Set<String> ids);
  Future<Result<void, AppFailure>> markMultipleAsRead(Set<String> ids, bool isRead);
  Future<Result<void, AppFailure>> insertVoicemail(Voicemail vm);
}

