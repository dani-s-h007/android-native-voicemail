import 'package:flutter/material.dart';
import 'package:voicemail/core/transcription/model_manager.dart';

class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  Map<String, bool> _installedStatus = {};
  final Map<String, double> _downloadProgress = {};
  String? _activeModelId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final active = await ModelManager.getActiveModelId();
    final Map<String, bool> status = {};

    for (var m in ModelManager.availableModels) {
      status[m.id] = await ModelManager.isModelInstalled(m.id);
    }

    setState(() {
      _activeModelId = active;
      _installedStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _download(ModelInfo model) async {
    setState(() => _downloadProgress[model.id] = 0.01);

    try {
      await ModelManager.downloadModel(
        model,
        onProgress: (p) => setState(() => _downloadProgress[model.id] = p),
      );
      setState(() => _downloadProgress.remove(model.id));
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${model.name} installed successfully!')),
        );
      }
    } catch (e) {
      setState(() => _downloadProgress.remove(model.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _delete(String modelId) async {
    await ModelManager.deleteModel(modelId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('On-Device Speech Models')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Card(
                  color: Color(0xFFF3E5F5),
                  child: Padding(
                    padding: EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Icon(Icons.offline_bolt, color: Colors.deepPurple, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Speech models run 100% on your phone. No audio is ever uploaded to any speech API.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...ModelManager.availableModels.map((model) {
                  final isInstalled = _installedStatus[model.id] ?? false;
                  final isActive = _activeModelId == model.id;
                  final progress = _downloadProgress[model.id];
                  final isDownloading = progress != null;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    shape: RoundedRectangleBorder(
                      side: isActive
                          ? const BorderSide(color: Colors.deepPurple, width: 2)
                          : BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(model.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${model.sizeMb} MB', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isDownloading) ...[
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 4),
                            Text('Downloading: ${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
                          ] else ...[
                            Row(
                              children: [
                                if (isActive)
                                  const Chip(
                                    label: Text('ACTIVE', style: TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: Colors.deepPurple,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                const Spacer(),
                                if (isInstalled) ...[
                                  if (!isActive)
                                    TextButton(
                                      onPressed: () async {
                                        await ModelManager.setActiveModelId(model.id);
                                        _refresh();
                                      },
                                      child: const Text('Set Active'),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _delete(model.id),
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Download'),
                                    onPressed: () => _download(model),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

