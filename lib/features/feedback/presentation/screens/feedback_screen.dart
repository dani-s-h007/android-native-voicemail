import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/logging/app_logger.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'Feature Suggestion';
  bool _attachDiagnosticLog = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Feature Suggestion',
    'Bug Report',
    'Mobile Carrier Forwarding Issue',
    'Audio & Transcription Feedback',
    'General Appreciation',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _requestAppReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        if (mounted) context.showSnackBar('Thank you for your rating!');
      }
    } catch (_) {
      if (mounted) context.showSnackBar('Thank you for rating ${AppConfig.appName}!');
    }
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      context.showErrorSnackBar('Please enter your feedback before submitting.');
      return;
    }

    setState(() => _isSubmitting = true);

    final buffer = StringBuffer();
    buffer.writeln('=== ${AppConfig.appName} User Feedback ===');
    buffer.writeln('Category: $_selectedCategory');
    buffer.writeln('App Version: ${AppConfig.version} (Build ${AppConfig.buildNumber})');
    buffer.writeln('Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('------------------------------------\n');
    buffer.writeln(text);
    buffer.writeln('\n------------------------------------');

    if (_attachDiagnosticLog) {
      buffer.writeln('\n=== Attached Sanitized Diagnostic Log ===');
      buffer.writeln(AppLogger.exportLogsAsText());
    }

    await Share.share(
      buffer.toString(),
      subject: '${AppConfig.appName} Feedback: $_selectedCategory',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      _feedbackController.clear();
      context.showSnackBar('Thank you! Feedback prepared for submission.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Feedback & Support',
        subtitle: 'Help improve ${AppConfig.appName}',
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          // In-App Rating Hero Card
          AppCard(
            variant: AppCardVariant.filled,
            color: context.colorScheme.primaryContainer.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 36, color: Colors.amber),
                AppSpacing.hSpace14,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enjoying ${AppConfig.appName}?',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.vSpace2,
                      Text(
                        'Leave a 5-star review on Google Play to support development.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _requestAppReview,
                  child: const Text('Rate'),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace20,

          // Category Selector
          Text(
            'FEEDBACK CATEGORY',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedCategory),
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
              labelText: 'Select Topic',
            ),
            items: _categories.map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          AppSpacing.vSpace16,

          // Description Input
          Text(
            'YOUR MESSAGE',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Describe your idea, report an issue with your carrier, or tell us how the assistant is working for you...',
              border: OutlineInputBorder(),
            ),
          ),
          AppSpacing.vSpace12,

          // Attach Diagnostics Toggle
          AppSwitchRow(
            leading: const Icon(Icons.bug_report_outlined),
            title: 'Attach Redacted Diagnostic Log',
            subtitle: 'Includes sanitized telephony decision trail (numbers redacted)',
            value: _attachDiagnosticLog,
            onChanged: (val) => setState(() => _attachDiagnosticLog = val),
          ),
          AppSpacing.vSpace24,

          // Submit Action Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? 'Preparing Feedback...' : 'Send Feedback to Developer'),
            onPressed: _isSubmitting ? null : _submitFeedback,
          ),
          AppSpacing.vSpace24,
        ],
      ),
    );
  }
}
