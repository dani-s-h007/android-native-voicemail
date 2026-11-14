import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicemail/core/logging/app_logger.dart';

class LocalAudioStorage {
  static Future<Directory?> getVoicemailDirectory() async {
    if (kIsWeb) return null;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final vmDir = Directory('${docsDir.path}/voicemails_private');
      if (!await vmDir.exists()) {
        await vmDir.create(recursive: true);
      }
      return vmDir;
    } catch (_) {
      return null;
    }
  }

  static Future<File?> saveAudioBytes(String jobId, List<int> bytes) async {
    if (kIsWeb) return null;
    try {
      final dir = await getVoicemailDirectory();
      if (dir == null) return null;
      final file = File('${dir.path}/$jobId.wav');
      return await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteAudioFile(String localPath) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return 0;
    try {
      final dir = await getVoicemailDirectory();
      if (dir == null) return 0;
      int total = 0;
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: false, followLinks: false)) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
