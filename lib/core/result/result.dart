sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get orNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  T getOrElse(T Function(E error) fallback) => switch (this) {
        Success(data: final d) => d,
        Failure(error: final e) => fallback(e),
      };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(E error) onFailure,
  }) =>
      switch (this) {
        Success(data: final d) => onSuccess(d),
        Failure(error: final e) => onFailure(e),
      };

  Result<R, E> map<R>(R Function(T data) transform) => switch (this) {
        Success(data: final d) => Success(transform(d)),
        Failure(error: final e) => Failure(e),
      };

  Result<R, E> flatMap<R>(Result<R, E> Function(T data) transform) =>
      switch (this) {
        Success(data: final d) => transform(d),
        Failure(error: final e) => Failure(e),
      };
}

final class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T, E> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Failure<T, E> && other.error == error);

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

