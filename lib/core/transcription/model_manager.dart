import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelInfo {
  final String id;
  final String name;
  final String languageCode;
  final String downloadUrl;
  final int sizeBytes;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  String get sizeMb => (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
}

class ModelManager {
  static const List<ModelInfo> availableModels = [
    ModelInfo(
      id: 'whisper_tiny_en',
      name: 'English (Ultra-Fast Tiny)',
      languageCode: 'en',
      downloadUrl: 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny.en/resolve/main/tiny.en-encoder.int8.onnx',
      sizeBytes: 41943040, // ~40MB
    ),
    ModelInfo(
      id: 'whisper_base_indic',
      name: 'Multilingual (Hindi, Ta, Te, Kn, Ml, En)',
      languageCode: 'multilingual',
      downloadUrl: 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base/resolve/main/base-encoder.int8.onnx',
      sizeBytes: 78643200, // ~75MB
    ),
    ModelInfo(
      id: 'indic_conformer_hi',
      name: 'Hindi High-Accuracy (AI4Bharat)',
      languageCode: 'hi',
      downloadUrl: 'https://huggingface.co/csukuangfj/sherpa-onnx-hindi/resolve/main/model.int8.onnx',
      sizeBytes: 52428800, // ~50MB
    ),
  ];

  static Future<Directory> getModelDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docs.path}/models_asr');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  static Future<File> getModelFile(String modelId) async {
    final dir = await getModelDirectory();
    return File('${dir.path}/$modelId.onnx');
  }

  static Future<bool> isModelInstalled(String modelId) async {
    final file = await getModelFile(modelId);
    return await file.exists();
  }

  static Future<String?> getActiveModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_asr_model_id');
  }

  static Future<void> setActiveModelId(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_asr_model_id', modelId);
  }

  static Future<void> downloadModel(
    ModelInfo model, {
    required void Function(double progress) onProgress,
  }) async {
    final file = await getModelFile(model.id);
    final request = http.Request('GET', Uri.parse(model.downloadUrl));
    final response = await http.Client().send(request);

    final totalBytes = response.contentLength ?? model.sizeBytes;
    int receivedBytes = 0;

    final sink = file.openWrite();
    await response.stream.listen((chunk) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      onProgress(receivedBytes / totalBytes);
    }).asFuture();

    await sink.flush();
    await sink.close();

    await setActiveModelId(model.id);
  }

  static Future<void> deleteModel(String modelId) async {
    final file = await getModelFile(modelId);
    if (await file.exists()) {
      await file.delete();
    }
    final active = await getActiveModelId();
    if (active == modelId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_asr_model_id');
    }
  }
}

