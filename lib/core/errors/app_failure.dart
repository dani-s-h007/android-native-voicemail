sealed class AppFailure implements Exception {
  final String message;
  final String? code;
  final dynamic cause;

  const AppFailure(this.message, {this.code, this.cause});

  @override
  String toString() => '$runtimeType: $message${code != null ? ' ($code)' : ''}';
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, {super.code, super.cause});
}

final class TelephonyFailure extends AppFailure {
  const TelephonyFailure(super.message, {super.code, super.cause});
}

final class PermissionFailure extends AppFailure {
  final String permission;
  const PermissionFailure(this.permission, super.message, {super.code, super.cause});
}

final class AudioFailure extends AppFailure {
  const AudioFailure(super.message, {super.code, super.cause});
}

final class TranscriptionFailure extends AppFailure {
  const TranscriptionFailure(super.message, {super.code, super.cause});
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.code, super.cause});
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message, {super.code, super.cause});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.code, super.cause});
}

