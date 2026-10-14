import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/errors/app_exception.dart';
import 'package:motocare/core/utils/result.dart';

void main() {
  group('Result & AppException Unit Tests', () {
    test('Result.success mengembalikan data dan isSuccess bernilai true', () {
      const Result<String> result = Result.success('data motor');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 'data motor');
      expect(result.exceptionOrNull, isNull);

      final transformed = result.map((data) => data.toUpperCase());
      expect(transformed.dataOrNull, 'DATA MOTOR');

      final value = result.when(
        onSuccess: (data) => 'Sukses: $data',
        onFailure: (err) => 'Gagal: ${err.message}',
      );
      expect(value, 'Sukses: data motor');
    });

    test('Result.failure mengembalikan exception dan isFailure bernilai true', () {
      const exception = NetworkException();
      const Result<String> result = Result.failure(exception);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.exceptionOrNull, isA<NetworkException>());

      final value = result.when(
        onSuccess: (data) => 'Sukses: $data',
        onFailure: (err) => 'Gagal: ${err.message}',
      );
      expect(value, contains('Koneksi internet bermasalah'));

      final fallback = result.getOrElse((_) => 'Data Fallback');
      expect(fallback, 'Data Fallback');
    });

    test('AppException.fromError memetakan error secara ramah', () {
      expect(
        AppException.fromError('SocketException: failed to connect'),
        isA<NetworkException>(),
      );
      expect(
        AppException.fromError('JWT expired / Unauthorized'),
        isA<UnauthorizedException>(),
      );
      expect(
        AppException.fromError('404 Not Found'),
        isA<NotFoundException>(),
      );
      expect(
        AppException.fromError('Permission denied'),
        isA<PermissionException>(),
      );
      expect(
        AppException.fromError('random unknown error'),
        isA<UnknownException>(),
      );
    });
  });
}
