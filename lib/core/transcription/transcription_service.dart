/// Abstract contract for on-device and remote transcription services.
abstract class TranscriptionService {
  Future<String> transcribeAudio({
    required String audioFilePath,
    String? languageHint,
  });

  Future<bool> isModelDownloaded({String? language});
}

/// Simulated mock transcription service for offline development and testing.
class MockTranscriptionService implements TranscriptionService {
  const MockTranscriptionService();

  @override
  Future<String> transcribeAudio({
    required String audioFilePath,
    String? languageHint,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'Automated transcript generated for $audioFilePath.';
  }

  @override
  Future<bool> isModelDownloaded({String? language}) async => true;
}
