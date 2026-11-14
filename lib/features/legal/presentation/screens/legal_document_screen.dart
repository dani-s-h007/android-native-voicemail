import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/legal/domain/legal_document.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String documentId;

  const LegalDocumentScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String _markdownContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = LegalDocType.fromId(widget.documentId);
    try {
      final content = await rootBundle.loadString(doc.assetPath);
      if (mounted) {
        setState(() {
          _markdownContent = content;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _markdownContent = '# ${doc.title}\n\n'
              '${doc.subtitle}\n\n'
              'Please visit the official online document at: ${doc.webUrl}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWebVersion(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) context.showErrorSnackBar('Unable to open web version');
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = LegalDocType.fromId(widget.documentId);

    return AppScaffold(
      appBar: AppAppBar(
        title: doc.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'View Online at danishk.web.app',
            onPressed: () => _openWebVersion(doc.webUrl),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.padding16,
              children: [
                AppCard(
                  variant: AppCardVariant.filled,
                  child: Row(
                    children: [
                      Icon(doc.icon, color: context.colorScheme.primary, size: 24),
                      AppSpacing.hSpace12,
                      Expanded(
                        child: Text(
                          'Official Legal Document • Republic of India Compliance',
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vSpace16,

                // Markdown body
                SelectableText(
                  _markdownContent,
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                AppSpacing.vSpace24,

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Hosted Web Version on danishk.web.app'),
                  onPressed: () => _openWebVersion(doc.webUrl),
                ),
                AppSpacing.vSpace24,
              ],
            ),
    );
  }
}

