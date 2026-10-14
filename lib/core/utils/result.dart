import '../errors/app_exception.dart';

/// Sealed class Result untuk penanganan operasi yang dapat gagal sesuai PRD 3.2
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppException exception) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        Failure<T>() => null,
      };

  AppException? get exceptionOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(exception: final e) => e,
      };

  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException exception) onFailure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => onSuccess(d),
      Failure<T>(exception: final e) => onFailure(e),
    };
  }

  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final d) => Result<R>.success(transform(d)),
      Failure<T>(exception: final e) => Result<R>.failure(e),
    };
  }

  T getOrElse(T Function(AppException exception) fallback) {
    return switch (this) {
      Success<T>(data: final d) => d,
      Failure<T>(exception: final e) => fallback(e),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception.message == other.exception.message;

  @override
  int get hashCode => exception.hashCode;
}
