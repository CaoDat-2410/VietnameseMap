import 'package:flutter_test/flutter_test.dart';
import 'package:vietnamese_map/core/utils/performance_utils.dart';

void main() {
  group('ApiDebouncer', () {
    test('runs action after delay', () async {
      final debouncer = ApiDebouncer(delay: Duration(milliseconds: 50));
      bool ran = false;
      debouncer.run(() => ran = true);
      expect(ran, isFalse);
      await Future.delayed(Duration(milliseconds: 100));
      expect(ran, isTrue);
      debouncer.dispose();
    });

    test('cancels previous action', () async {
      final debouncer = ApiDebouncer(delay: Duration(milliseconds: 100));
      int count = 0;
      debouncer.run(() => count++);
      debouncer.run(() => count++);
      debouncer.run(() => count++);
      expect(count, 0);
      await Future.delayed(Duration(milliseconds: 200));
      expect(count, 1);
      debouncer.dispose();
    });

    test('cancel stops pending action', () async {
      final debouncer = ApiDebouncer(delay: Duration(milliseconds: 100));
      bool ran = false;
      debouncer.run(() => ran = true);
      debouncer.cancel();
      await Future.delayed(Duration(milliseconds: 200));
      expect(ran, isFalse);
      debouncer.dispose();
    });
  });

  group('Throttler', () {
    test('executes first call immediately', () {
      final throttler = Throttler(duration: Duration(milliseconds: 100));
      int count = 0;
      throttler.run(() => count++);
      expect(count, 1);
    });

    test('throttles rapid calls', () async {
      final throttler = Throttler(duration: Duration(milliseconds: 50));
      int count = 0;
      throttler.run(() => count++);
      throttler.run(() => count++);
      throttler.run(() => count++);
      expect(count, 1);
    });

    test('allows call after duration passes', () async {
      final throttler = Throttler(duration: Duration(milliseconds: 30));
      int count = 0;
      throttler.run(() => count++);
      await Future.delayed(Duration(milliseconds: 50));
      throttler.run(() => count++);
      expect(count, 2);
    });
  });

  group('PaginationHelper', () {
    test('calculates correct offset', () {
      expect(PaginationHelper.getOffset(1), 0);
      expect(PaginationHelper.getOffset(2), 20);
      expect(PaginationHelper.getOffset(3), 40);
      expect(PaginationHelper.getOffset(1, pageSize: 10), 0);
      expect(PaginationHelper.getOffset(5, pageSize: 10), 40);
    });

    test('hasMorePages returns true when count equals pageSize', () {
      expect(PaginationHelper.hasMorePages(20, 1), isTrue);
      expect(PaginationHelper.hasMorePages(10, 1), isFalse);
    });

    test('getNextPage increments correctly', () {
      expect(PaginationHelper.getNextPage(1, 20), 2);
      expect(PaginationHelper.getNextPage(2, 10), 2);
      expect(PaginationHelper.getNextPage(3, 5), 3);
    });
  });

  group('MemoCache', () {
    test('stores and retrieves values', () {
      final cache = MemoCache<String, int>();
      cache.set('key', 42);
      expect(cache.get('key'), 42);
    });

    test('returns null for missing key', () {
      final cache = MemoCache<String, int>();
      expect(cache.get('missing'), isNull);
    });

    test('invalidates specific key', () {
      final cache = MemoCache<String, int>();
      cache.set('key1', 1);
      cache.set('key2', 2);
      cache.invalidate('key1');
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), 2);
    });

    test('clear removes all entries', () {
      final cache = MemoCache<String, int>();
      cache.set('key1', 1);
      cache.set('key2', 2);
      cache.clear();
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });

    test('respects maxSize limit', () {
      final cache = MemoCache<int, int>(maxSize: 2);
      cache.set(1, 1);
      cache.set(2, 2);
      cache.set(3, 3); // Should evict key 1
      expect(cache.get(1), isNull);
      expect(cache.get(2), 2);
      expect(cache.get(3), 3);
    });
  });

  group('BatchProcessor', () {
    test('flushes after batch window', () async {
      List<int> flushed = [];
      final processor = BatchProcessor<int>(
        onFlush: (items) => flushed.addAll(items),
        batchWindow: Duration(milliseconds: 20),
      );
      processor.add(1);
      processor.add(2);
      expect(flushed, isEmpty);
      await Future.delayed(Duration(milliseconds: 50));
      expect(flushed, [1, 2]);
      processor.dispose();
    });

    test('clears buffer on dispose', () async {
      List<int> flushed = [];
      final processor = BatchProcessor<int>(
        onFlush: (items) => flushed.addAll(items),
        batchWindow: Duration(milliseconds: 100),
      );
      processor.add(1);
      processor.dispose();
      await Future.delayed(Duration(milliseconds: 50));
      expect(flushed, isEmpty);
    });
  });

  group('PerformanceTracker', () {
    test('measures duration between start and end', () {
      final tracker = PerformanceTracker();
      tracker.start('test');
      // Simulate some work
      tracker.end('test');
      final duration = tracker.getDuration('test');
      expect(duration, isNotNull);
      expect(duration!.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('returns null for missing key', () {
      final tracker = PerformanceTracker();
      expect(tracker.getDuration('missing'), isNull);
    });

    test('clears all metrics', () {
      final tracker = PerformanceTracker();
      tracker.start('test1');
      tracker.start('test2');
      tracker.clear();
      expect(tracker.getDuration('test1'), isNull);
      expect(tracker.getDuration('test2'), isNull);
    });
  });

  group('RebuildOptimizer', () {
    test('shouldRebuild returns false for same values', () {
      final value = 'test';
      expect(RebuildOptimizer.shouldRebuild(value, value), isFalse);
    });

    test('shouldRebuild returns true for different values', () {
      expect(RebuildOptimizer.shouldRebuild('old', 'new'), isTrue);
    });

    test('shouldRebuild returns true when one is null', () {
      expect(RebuildOptimizer.shouldRebuild(null, 'new'), isTrue);
      expect(RebuildOptimizer.shouldRebuild('old', null), isTrue);
    });
  });

  group('ListDiff', () {
    test('computes added items correctly', () {
      final diff = ListDiff<int>.compute([1, 2], [1, 2, 3]);
      expect(diff.added, [3]);
      expect(diff.removed, isEmpty);
      expect(diff.unchanged, [1, 2]);
    });

    test('computes removed items correctly', () {
      final diff = ListDiff<int>.compute([1, 2, 3], [1, 2]);
      expect(diff.removed, [3]);
      expect(diff.added, isEmpty);
    });

    test('computes unchanged items correctly', () {
      final diff = ListDiff<int>.compute([1, 2], [1, 2]);
      expect(diff.unchanged, [1, 2]);
      expect(diff.hasChanges, isFalse);
    });

    test('detects multiple changes', () {
      final diff = ListDiff<int>.compute([1, 2, 3], [4, 5, 6]);
      expect(diff.added, [4, 5, 6]);
      expect(diff.removed, [1, 2, 3]);
      expect(diff.hasChanges, isTrue);
    });
  });

  group('ImagePlaceholder', () {
    test('getUrl returns sized URL', () {
      expect(ImagePlaceholder.getUrl('http://example.com/img.jpg', 100),
          'http://example.com/img.jpg?w=100');
    });

    test('getUrl returns original for size 0', () {
      expect(ImagePlaceholder.getUrl('http://example.com/img.jpg', 0),
          'http://example.com/img.jpg');
    });

    test('constants are defined', () {
      expect(ImagePlaceholder.thumbnail, 100);
      expect(ImagePlaceholder.small, 200);
      expect(ImagePlaceholder.medium, 400);
      expect(ImagePlaceholder.large, 800);
      expect(ImagePlaceholder.original, 0);
    });
  });
}
