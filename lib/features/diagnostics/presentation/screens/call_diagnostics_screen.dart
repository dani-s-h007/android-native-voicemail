import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/logging/app_logger.dart';
import 'package:voicemail/core/reliability/reliability_service.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class CallDiagnosticsScreen extends StatefulWidget {
  const CallDiagnosticsScreen({super.key});

  @override
  State<CallDiagnosticsScreen> createState() => _CallDiagnosticsScreenState();
}

class _CallDiagnosticsScreenState extends State<CallDiagnosticsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() => _isLoading = true);
    final logs = await ReliabilityService.getDiagnosticLogs(limit: 50);

    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Clear Call Decision Logs?',
      message: 'This will delete the local audit trail of screened calls.',
      confirmLabel: 'Clear',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ReliabilityService.clearDiagnosticLogs();
      _refreshLogs();
    }
  }

  Future<void> _exportLogs() async {
    final buffer = StringBuffer();
    buffer.writeln('=== Vani Voicemail Call Diagnostics Audit Trail ===');
    buffer.writeln('Exported on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Device: Android / Realme UI');
    buffer.writeln('--------------------------------------------------\n');

    for (final item in _logs) {
      final time = item['timestamp'] ?? '';
      final rawNum = item['caller_number'] ?? '';
      final num = AppLogger.redact(rawNum.toString());
      final decision = item['decision'] ?? '';
      final reason = item['reason'] ?? '';
      final carrier = item['carrier_response'] ?? '';

      buffer.writeln('[$time] CALLER: $num');
      buffer.writeln('DECISION: $decision');
      buffer.writeln('REASON: $reason');
      buffer.writeln('CARRIER: $carrier');
      buffer.writeln('--------------------------------------------------');
    }

    await Share.share(
      buffer.toString(),
      subject: 'Vani Voicemail Call Diagnostic Audit',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _logs.where((l) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      final num = (l['caller_number'] ?? '').toString().toLowerCase();
      final dec = (l['decision'] ?? '').toString().toLowerCase();
      final rea = (l['reason'] ?? '').toString().toLowerCase();
      return num.contains(q) || dec.contains(q) || rea.contains(q);
    }).toList();

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Why Did This Call Not Work?',
        subtitle: 'Per-call decision audit trail',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export Logs',
            onPressed: _logs.isEmpty ? null : _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
            onPressed: _logs.isEmpty ? null : _clearLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshLogs,
              child: ListView(
                padding: AppSpacing.padding16,
                children: [
                  AppSearchBar(
                    hintText: 'Filter decisions by number, status, or reason...',
                    onChanged: (val) => setState(() => _filterQuery = val.trim()),
                    onClear: () => setState(() => _filterQuery = ''),
                  ),
                  AppSpacing.vSpace16,

                  if (filtered.isEmpty)
                    AppEmptyState(
                      icon: _logs.isEmpty ? Icons.event_note_outlined : Icons.search_off_rounded,
                      title: _logs.isEmpty ? 'No Call Diagnostics Yet' : 'No Matching Logs',
                      description: _logs.isEmpty
                          ? 'Incoming call screening, DND decisions, and auto-reply events will appear here in real-time as calls arrive.'
                          : 'No call screening events match your filter query.',
                    )
                  else
                    ...filtered.map((item) => _buildDecisionCard(item)),
                ],
              ),
            ),
    );
  }

  Widget _buildDecisionCard(Map<String, dynamic> item) {
    final colorScheme = context.colorScheme;
    final timeStr = item['timestamp']?.toString().substring(0, 19).replaceAll('T', ' ') ?? '';
    final rawNumber = item['caller_number']?.toString() ?? 'Unknown';
    final number = AppLogger.redact(rawNumber);
    final decision = item['decision']?.toString() ?? 'UNKNOWN';
    final reason = item['reason']?.toString() ?? '';
    final carrier = item['carrier_response']?.toString() ?? '';

    Color badgeBg;
    Color badgeFg;

    if (decision.contains('ALLOWED') || decision.contains('VIP')) {
      badgeBg = Colors.green.shade50;
      badgeFg = Colors.green.shade800;
    } else if (decision.contains('VOICEMAIL') || decision.contains('SCREENED')) {
      badgeBg = Colors.blue.shade50;
      badgeFg = Colors.blue.shade800;
    } else {
      badgeBg = Colors.amber.shade50;
      badgeFg = Colors.amber.shade900;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        variant: AppCardVariant.outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.call_end_outlined, size: 18),
                    AppSpacing.hSpace8,
                    Text(
                      number,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    decision,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeFg,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vSpace8,
            Text(
              reason,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.35,
              ),
            ),
            if (carrier.isNotEmpty) ...[
              AppSpacing.vSpace6,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.network_check_rounded, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      carrier,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            AppSpacing.vSpace8,
            Text(
              timeStr,
              style: context.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
