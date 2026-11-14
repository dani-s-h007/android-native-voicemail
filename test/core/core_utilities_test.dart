import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/core/errors/app_failure.dart';
import 'package:voicemail/core/extensions/datetime_extensions.dart';
import 'package:voicemail/core/logging/app_logger.dart';
import 'package:voicemail/core/result/result.dart';

void main() {
  group('Result Type Tests', () {
    test('Success returns data and isSuccess is true', () {
      const Result<int, AppFailure> result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.orNull, 42);
      expect(result.getOrElse((_) => 0), 42);
    });

    test('Failure returns error and isFailure is true', () {
      const Result<int, AppFailure> result =
          Failure(DatabaseFailure('Disk error'));
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.orNull, isNull);
      expect(result.getOrElse((e) => -1), -1);
    });

    test('map transforms success data and leaves failure intact', () {
      const Result<int, AppFailure> success = Success(10);
      final mappedSuccess = success.map((v) => 'Value: $v');
      expect(mappedSuccess.orNull, 'Value: 10');
      expect(mappedSuccess.isSuccess, isTrue);

      const Result<int, AppFailure> failure = Failure(AudioFailure('Codec error'));
      final mappedFailure = failure.map((v) => 'Value: $v');
      expect(mappedFailure.isFailure, isTrue);
      expect(mappedFailure.orNull, isNull);
    });

    test('fold correctly routes to success and failure branches', () {
      const Result<String, AppFailure> res = Success('Vani');
      final output = res.fold(
        onSuccess: (data) => 'Hello $data',
        onFailure: (err) => 'Error',
      );
      expect(output, 'Hello Vani');
    });
  });

  group('Privacy-Safe AppLogger Tests', () {
    test('redact masks sensitive Indian phone numbers', () {
      const text = 'Caller number is +919876543210 from Kerala';
      final redacted = AppLogger.redact(text);
      expect(redacted.contains('9876543210'), isFalse);
      expect(redacted, contains('****'));
    });

    test('redact masks emails', () {
      const text = 'User email is test.user@gmail.com for auth';
      final redacted = AppLogger.redact(text);
      expect(redacted.contains('test.user@gmail.com'), isFalse);
      expect(redacted, contains('***@gmail.com'));
    });
  });

  group('DateTimeExtensions Tests', () {
    test('isToday returns true for current date', () {
      final now = DateTime.now();
      expect(now.isToday, isTrue);
      expect(now.dateGroupHeader, 'Today');
    });

    test('formattedMinutesSeconds formats duration accurately', () {
      const duration = Duration(minutes: 1, seconds: 25);
      expect(duration.formattedMinutesSeconds, '1:25');

      const shortDuration = Duration(seconds: 7);
      expect(shortDuration.formattedMinutesSeconds, '0:07');
    });
  });
}
