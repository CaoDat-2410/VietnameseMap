import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/core/errors/failures.dart';
import 'package:vietnamese_map/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes its value and invokes ok callback', () {
      final result = Ok<String>('success');
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrThrow, 'success');
      expect(result.when(ok: (value) => value, err: (failure) => failure.message), 'success');
    });

    test('Err preserves failure and throws from valueOrThrow', () {
      const failure = ValidationFailure('invalid input');
      final result = Err<String>(failure);
      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(() => result.valueOrThrow, throwsA(isA<StateError>()));
      expect(result.when(ok: (value) => value, err: (error) => error.message), 'invalid input');
    });

    test('supports nullable and nested values', () {
      final nullable = Ok<String?>(null);
      final nested = Ok<Result<String>>(const Ok<String>('inner'));
      expect(nullable.valueOrThrow, isNull);
      expect(nested.valueOrThrow.valueOrThrow, 'inner');
    });
  });
}