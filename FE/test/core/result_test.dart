import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/core/utils/result.dart';

void main() {
  group('Result type tests', () {
    test('Ok wraps value correctly', () {
      final result = Ok<String, String>('success');
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrThrow, 'success');
      expect(result.errorOrNull, isNull);
    });

    test('Err wraps error correctly', () {
      final result = Err<String, String>('error');
      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(() => result.valueOrThrow, throwsException);
      expect(result.errorOrNull, 'error');
    });

    test('Ok.when executes onOk callback', () {
      final result = Ok<int, String>(42);
      String? value;
      result.when(
        ok: (v) => value = 'got $v',
        err: (e) => value = 'error: $e',
      );
      expect(value, 'got 42');
    });

    test('Err.when executes onErr callback', () {
      final result = Err<int, String>('failed');
      String? value;
      result.when(
        ok: (v) => value = 'got $v',
        err: (e) => value = 'error: $e',
      );
      expect(value, 'error: failed');
    });

    test('map transforms Ok value', () {
      final result = Ok<int, String>(5);
      final mapped = result.map((v) => v * 2);
      expect(mapped.valueOrThrow, 10);
    });

    test('map does not transform Err value', () {
      final result = Err<int, String>('error');
      final mapped = result.map((v) => v * 2);
      expect(mapped.isErr, isTrue);
      expect(mapped.errorOrNull, 'error');
    });

    test('mapErr transforms Err error', () {
      final result = Err<int, String>('error');
      final mapped = result.mapErr((e) => 'mapped: $e');
      expect(mapped.errorOrNull, 'mapped: error');
    });

    test('Ok valueOrNull returns value', () {
      final result = Ok<String, String>('value');
      expect(result.valueOrNull, 'value');
    });

    test('Err valueOrNull returns null', () {
      final result = Err<String, String>('error');
      expect(result.valueOrNull, isNull);
    });

    test('okOrElse provides default for Err', () {
      final result = Err<String, String>('error');
      expect(result.okOrElse(() => 'default'), 'default');
    });

    test('okOrElse returns value for Ok', () {
      final result = Ok<String, String>('value');
      expect(result.okOrElse(() => 'default'), 'value');
    });
  });

  group('Result edge cases', () {
    test('nested Result works correctly', () {
      final inner = Ok<String, String>('inner');
      final outer = Ok<Result<String, String>, String>(inner);
      expect(outer.valueOrThrow.valueOrThrow, 'inner');
    });

    test('Result with null value', () {
      final result = Ok<String?, String>(null);
      expect(result.valueOrNull, isNull);
    });

    test('Result with empty string value', () {
      final result = Ok<String, String>('');
      expect(result.valueOrThrow, '');
    });

    test('Result with numeric types', () {
      final intResult = Ok<int, String>(0);
      final doubleResult = Ok<double, String>(0.0);
      expect(intResult.valueOrThrow, 0);
      expect(doubleResult.valueOrThrow, 0.0);
    });
  });
}
