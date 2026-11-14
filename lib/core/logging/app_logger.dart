import 'dart:collection';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String format() {
    final timeStr = timestamp.toIso8601String().substring(11, 23);
    final levelStr = level.name.toUpperCase().padRight(5);
    return '[$timeStr][$levelStr][$tag] $message';
  }
}

class AppLogger {
  static const int maxBufferSize = 500;
  static final Queue<LogEntry> _buffer = Queue<LogEntry>();

  /// Regex for redacting sensitive Indian phone numbers (+91 XXXXX XXXXX or 10 digits)
  static final RegExp _phoneRegex = RegExp(
    r'(?:\+91[\-\s]?)?[6-9]\d{9}',
  );

  /// Regex for redacting email addresses
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static String redact(String input) {
    var sanitized = input.replaceAllMapped(_phoneRegex, (match) {
      final text = match.group(0)!;
      if (text.length >= 10) {
        return '${text.substring(0, 3)}****${text.substring(text.length - 3)}';
      }
      return '****';
    });

    sanitized = sanitized.replaceAllMapped(_emailRegex, (match) {
      final email = match.group(0)!;
      final parts = email.split('@');
      if (parts.length == 2 && parts[0].length > 2) {
        return '${parts[0].substring(0, 2)}***@${parts[1]}';
      }
      return '***@email.com';
    });

    return sanitized;
  }

  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void w(String tag, String message, [Object? error]) =>
      _log(LogLevel.warning, tag, message, error);

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, tag, message, error, stackTrace);

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final sanitizedMessage = redact(message);
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: sanitizedMessage,
      error: error,
      stackTrace: stackTrace,
    );

    if (_buffer.length >= maxBufferSize) {
      _buffer.removeFirst();
    }
    _buffer.addLast(entry);

    if (kDebugMode) {
      debugPrint(entry.format());
      if (error != null) {
        debugPrint('  Error: $error');
      }
    }
  }

  static List<LogEntry> getLogs() => List.unmodifiable(_buffer);

  static String exportLogsAsText() {
    return _buffer.map((e) => e.format()).join('\n');
  }

  static void clear() {
    _buffer.clear();
  }
}

