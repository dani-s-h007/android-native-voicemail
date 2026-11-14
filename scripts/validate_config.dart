import 'dart:io';

/// Build-time validation script for CI/CD and pre-commit checks.
/// Runs in pure Dart without requiring the Flutter engine.
///
/// Usage: dart scripts/validate_config.dart [prod|dev|staging]
void main(List<String> args) {
  final flavor = (args.isNotEmpty ? args.first.toLowerCase() : 'prod');
  stdout.writeln('Checking configuration placeholders for flavor: $flavor...');

  final file = File('lib/app/config/app_config.dart');
  if (!file.existsSync()) {
    stderr.writeln("ERROR: Cannot find 'lib/app/config/app_config.dart'");
    exitCode = 1;
    return;
  }

  final lines = file.readAsLinesSync();
  final violations = <String>[];

  final todoRegex = RegExp(r"=\s*'([^']*(TODO_UPDATE|example\.com)[^']*)'");

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.startsWith('//') || line.startsWith('*')) continue;

    final match = todoRegex.firstMatch(line);
    if (match != null) {
      final value = match.group(1);
      violations.add('Line ${i + 1}: Found placeholder value "$value"');
    }
  }

  if (violations.isNotEmpty) {
    stdout.writeln('\n======================================================');
    stdout.writeln(' CONFIGURATION PLACEHOLDERS DETECTED ($flavor)');
    stdout.writeln('======================================================');
    for (final v in violations) {
      stdout.writeln(' * $v');
    }
    stdout.writeln('\nRefer to docs/UPDATE_CHECKLIST.md for release requirements.');
    stdout.writeln('======================================================\n');

    if (flavor == 'prod') {
      stderr.writeln('FAIL: Build rejected for prod flavor. All TODO_UPDATE markers must be resolved.');
      exitCode = 1;
    } else {
      stdout.writeln('PASS (Warning only): Non-prod flavor $flavor permitted with placeholders.');
    }
  } else {
    stdout.writeln('SUCCESS: Zero TODO_UPDATE placeholders found. Configuration ready for release.');
  }
}
