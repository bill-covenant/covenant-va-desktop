import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Payloads with more items than this are JSON-encoded on a background
/// isolate via [compute] so large writes don't jank the UI thread.
const int kCacheComputeThreshold = 20;

String _encodeJsonList(List<Map<String, dynamic>> items) => json.encode(items);

/// Encodes [items] to JSON, off the UI thread when the payload is large.
Future<String> encodeJsonListForCache(List<Map<String, dynamic>> items) {
  if (items.length > kCacheComputeThreshold) {
    return compute(_encodeJsonList, items);
  }
  return Future.value(_encodeJsonList(items));
}

/// Debounces SharedPreferences writes of JSON lists.
///
/// Each call to [schedule] replaces any pending write for the same key and
/// restarts the timer. The payload builder is only invoked when the write
/// actually happens. Call [flush] to write pending data immediately (e.g. on
/// dispose / conversation switch) or [cancel] to drop it. The writer never
/// touches widget state, so it is safe to flush after a widget is disposed.
class DebouncedJsonCache {
  final Duration delay;

  DebouncedJsonCache({this.delay = const Duration(seconds: 2)});

  Timer? _timer;
  final Map<String, List<Map<String, dynamic>> Function()> _pending = {};

  void schedule(String key, List<Map<String, dynamic>> Function() buildPayload) {
    _pending[key] = buildPayload;
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  /// Writes all pending payloads now.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty) return;

    final writes = Map.of(_pending);
    _pending.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in writes.entries) {
        final encoded = await encodeJsonListForCache(entry.value());
        await prefs.setString(entry.key, encoded);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to write cache: $e');
    }
  }

  /// Drops any pending writes without saving them.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
  }
}
