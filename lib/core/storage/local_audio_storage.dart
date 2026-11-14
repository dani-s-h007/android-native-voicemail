import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:voicemail/core/logging/app_logger.dart';

class LocalAudioStorage {
  static Future<Directory> getVoicemailDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final vmDir = Directory('${docsDir.path}/voicemails_private');
    if (!await vmDir.exists()) {
      await vmDir.create(recursive: true);
    }
    return vmDir;
  }

  static Future<File> saveAudioBytes(String jobId, List<int> bytes) async {
    final dir = await getVoicemailDirectory();
    final file = File('${dir.path}/$jobId.wav');
    return await file.writeAsBytes(bytes, flush: true);
  }

  static Future<void> deleteAudioFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.w('LocalAudioStorage', 'Warning deleting local audio file: $e');
    }
  }

  static Future<int> getTotalStorageBytes() async {
    final dir = await getVoicemailDirectory();
    int total = 0;
    if (await dir.exists()) {
      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }
    return total;
  }
}

