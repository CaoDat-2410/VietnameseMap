import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/core/utils/date_time_utils.dart';

void main() {
  test('formatDateTime returns N/A for null', () {
    expect(formatDateTime(null), 'N/A');
  });

  test('formatDateTime returns a user-friendly local value', () {
    final value = DateTime(2026, 6, 20, 13, 59);
    expect(formatDateTime(value), '20/06/2026 13:59');
  });

  test('parseDateTime returns null for missing values', () {
    expect(parseDateTime(null), isNull);
    expect(parseDateTime(''), isNull);
  });
}
