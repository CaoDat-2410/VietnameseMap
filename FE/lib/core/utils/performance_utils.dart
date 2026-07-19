import 'dart:async';
import 'package:flutter/foundation.dart';

/// API Debouncer - Prevents rapid API calls
class ApiDebouncer {
  final Duration delay;
  Timer? _timer;

  ApiDebouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Throttler - Limits function calls to a maximum rate
class Throttler {
  final Duration duration;
  DateTime? _lastCall;

  Throttler({this.duration = const Duration(milliseconds: 100)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastCall == null ||
        now.difference(_lastCall!) >= duration) {
      _lastCall = now;
      action();
    }
  }
}

/// Pagination helper
class PaginationHelper {
  static const int defaultPageSize = 20;

  /// Calculate offset for pagination
  static int getOffset(int page, {int pageSize = defaultPageSize}) {
    return (page - 1) * pageSize;
  }

  /// Check if there are more pages
  static bool hasMorePages(int currentCount, int page, {int pageSize = defaultPageSize}) {
    return currentCount >= pageSize;
  }

  /// Get next page number
  static int getNextPage(int currentPage, int currentCount, {int pageSize = defaultPageSize}) {
    return hasMorePages(currentCount, currentPage, pageSize: pageSize)
        ? currentPage + 1
        : currentPage;
  }
}

/// Memoization cache for expensive computations
class MemoCache<K, V> {
  final int maxSize;
  final Duration? ttl;
  final Map<K, _CacheEntry<V>> _cache = {};

  MemoCache({this.maxSize = 100, this.ttl});

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check TTL
    if (ttl != null && DateTime.now().difference(entry.timestamp) > ttl!) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void set(K key, V value) {
    if (_cache.length >= maxSize) {
      // Remove oldest entry
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = _CacheEntry(value);
  }

  void invalidate(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry(this.value) : timestamp = DateTime.now();
}

/// Batch processor for API calls
class BatchProcessor<T> {
  final Duration batchWindow;
  final void Function(List<T>) onFlush;
  final List<T> _buffer = [];
  Timer? _timer;

  BatchProcessor({
    required this.onFlush,
    this.batchWindow = const Duration(milliseconds: 100),
  });

  void add(T item) {
    _buffer.add(item);
    _timer ??= Timer(batchWindow, _flush);
  }

  void _flush() {
    if (_buffer.isNotEmpty) {
      onFlush(List.from(_buffer));
      _buffer.clear();
    }
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _buffer.clear();
  }
}

/// Performance metrics tracker
class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._();

  final Map<String, _Metric> _metrics = {};

  void start(String key) {
    _metrics[key] = _Metric(startTime: DateTime.now());
  }

  void end(String key) {
    final metric = _metrics[key];
    if (metric != null) {
      metric.endTime = DateTime.now();
    }
  }

  Duration? getDuration(String key) {
    final metric = _metrics[key];
    if (metric != null && metric.endTime != null) {
      return metric.endTime!.difference(metric.startTime);
    }
    return null;
  }

  void clear() {
    _metrics.clear();
  }

  void log(String key) {
    final duration = getDuration(key);
    if (duration != null) {
      debugPrint('$key: ${duration.inMilliseconds}ms');
    }
  }
}

class _Metric {
  final DateTime startTime;
  DateTime? endTime;

  _Metric({required this.startTime});
}

/// Widget rebuild optimizer
class RebuildOptimizer {
  static bool shouldRebuild(Object? old, Object? current) {
    if (old == null && current == null) return false;
    if (old == null || current == null) return true;
    return old != current;
  }
}

/// List diff helper for efficient list updates
class ListDiff<T> {
  final List<T> added;
  final List<T> removed;
  final List<T> unchanged;

  ListDiff({
    required this.added,
    required this.removed,
    required this.unchanged,
  });

  factory ListDiff.compute(List<T> oldList, List<T> newList) {
    final oldSet = oldList.toSet();
    final newSet = newList.toSet();

    return ListDiff(
      added: newList.where((item) => !oldSet.contains(item)).toList(),
      removed: oldList.where((item) => !newSet.contains(item)).toList(),
      unchanged: newList.where((item) => oldSet.contains(item)).toList(),
    );
  }

  bool get hasChanges => added.isNotEmpty || removed.isNotEmpty;
}

/// Image placeholder sizes for responsive loading
class ImagePlaceholder {
  static const int thumbnail = 100;
  static const int small = 200;
  static const int medium = 400;
  static const int large = 800;
  static const int original = 0;

  static String getUrl(String baseUrl, int size) {
    if (size == original) return baseUrl;
    // Append size parameter based on your image service
    return '$baseUrl?w=$size';
  }
}

/// Memory usage helper
class MemoryHelper {
  static int estimateWidgetSize(Object widget) {
    // Rough estimate based on widget type
    return 100; // bytes
  }

  static void logMemoryUsage(String label) {
    if (kDebugMode) {
      // In production, use dart:developer getCurrentRSS()
      debugPrint('$label: Memory check');
    }
  }
}
