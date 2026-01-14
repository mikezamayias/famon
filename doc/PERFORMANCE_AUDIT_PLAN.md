# Performance and Memory Audit

## Executive Summary

This audit identifies performance and memory concerns in the Firebase Analytics Monitor CLI tool, focusing on areas that impact long-running monitoring sessions. The tool processes a continuous stream of logcat data, making efficient resource usage critical.

---

## Findings

### HIGH Severity

#### 1. RegExp Compiled Per Parse Call in `_parseParams()`
**File:** `lib/src/services/log_parser_service.dart:221-240`

**Issue:** 12 RegExp patterns are compiled inside `_parseParams()` on every invocation. Since `_parseParams()` is called for every parsed event (and sometimes recursively for items), this creates significant overhead.

```dart
// CURRENT (inefficient)
Map<String, String> _parseParams(String paramsString) {
  final patterns = [
    RegExp(r'(\w+)=([^,\[\]{}]+)(?=[,\]}]|$)'),  // compiled every call
    RegExp(r'(\w+)=String\(([^)]*)\)'),          // compiled every call
    // ... 10 more patterns
  ];
}
```

**Fix:** Move patterns to static final class members:
```dart
static final List<RegExp> _paramPatterns = [
  RegExp(r'(\w+)=([^,\[\]{}]+)(?=[,\]}]|$)'),
  RegExp(r'(\w+)=String\(([^)]*)\)'),
  // ...
];
```

#### 2. RegExp Compiled Per Parse Call in `_parseItems()`
**File:** `lib/src/services/log_parser_service.dart:339-348`

**Issue:** Two RegExp patterns compiled on each `_parseItems()` call.

#### 3. RegExp Compiled Per Value Clean in `_cleanValue()`
**File:** `lib/src/services/log_parser_service.dart:385-394`

**Issue:** Six RegExp patterns compiled every time a value is cleaned. This method is called for every parameter value.

#### 4. Missing Signal Handlers for Graceful Shutdown
**File:** `lib/src/commands/monitor_command.dart`, `lib/src/cli/commands/filtered_monitor_command.dart`

**Issue:** No SIGINT/SIGTERM handlers to gracefully terminate the adb process and close resources.

**Fix:** Add signal handling:
```dart
final sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
  process.kill();
  // cleanup resources
});
```

---

### MEDIUM Severity

#### 5. RegExp Compiled Per Timestamp Parse
**File:** `lib/src/shared/log_timestamp_parser.dart:12`

**Issue:** Timestamp parsing regex compiled on every call. This is called for every event.

**Fix:** Make pattern static:
```dart
static final _timestampPattern = RegExp(
  r'(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d{3})',
);
```

#### 6. RegExp Compiled Per Logcat Line in MonitorCommand
**File:** `lib/src/commands/monitor_command.dart:228`

**Issue:** Firebase relevance check regex compiled for every logcat line:
```dart
final isFirebaseRelated = RegExp(
  r'(FA|FA-SVC|FirebaseAnalytics|FirebaseCrashlytics)',
).hasMatch(line);
```

#### 7. RegExp Compiled Per Validation in FilteredMonitorCommand
**File:** `lib/src/cli/commands/filtered_monitor_command.dart:379`

**Issue:** Parameter name validation regex compiled per validation call.

#### 8. Unbounded EventCache Growth
**File:** `lib/src/services/event_cache_service.dart`

**Issue:** `_uniqueEventNames` and `_eventCounts` grow unbounded. In long monitoring sessions (hours/days), memory usage increases continuously.

**Fix:** Implement LRU eviction or maximum size limits:
```dart
static const _maxCacheSize = 10000;

void addEvent(String eventName) {
  if (_eventCounts.length >= _maxCacheSize) {
    _evictLeastFrequent();
  }
  // ...
}
```

#### 9. Database Connection Never Closed
**File:** `lib/src/database/isar_database.dart`

**Issue:** `Isar.close()` is never called, preventing clean resource release.

**Fix:** Add dispose method and call from commands:
```dart
Future<void> dispose() async {
  await _isar?.close();
}
```

#### 10. stderr Stream Not Consumed
**File:** `lib/src/commands/monitor_command.dart`, `lib/src/cli/commands/filtered_monitor_command.dart`

**Issue:** The adb process stderr is not consumed, which could cause buffer overflow if adb produces error output.

**Fix:** Drain stderr:
```dart
process.stderr.drain<void>();
```

---

### LOW Severity

#### 11. Repeated List.unmodifiable() Allocations
**File:** `lib/src/services/event_cache_service.dart`

**Issue:** Methods like `allEventNames`, `getEventsByFrequency()`, `getTopEvents()` create new unmodifiable list wrappers on each call.

**Mitigation:** Cache results with dirty flag, or document that callers should cache.

#### 12. RegExp Compiled Per Search in EventCacheService
**File:** `lib/src/services/event_cache_service.dart:51`

**Issue:** User-provided regex pattern compiled on each `searchEvents()` call. This is acceptable since patterns vary, but could cache recent patterns.

#### 13. String Allocations in _cleanValue()
**File:** `lib/src/services/log_parser_service.dart:389-395`

**Issue:** Chain of `replaceAll()` creates intermediate strings. Minor impact but could be optimized with single-pass cleaning.

---

## Implementation Priority

### Phase 1: Critical Performance (High Impact, Low Risk)
1. Make all regex patterns static final in `LogParserService`
2. Make timestamp pattern static final in `LogTimestampParser`
3. Make Firebase relevance pattern static final in `MonitorCommand`
4. Make validation pattern static final in `FilteredMonitorCommand`

### Phase 2: Resource Management (Medium Impact)
5. Add signal handlers (SIGINT/SIGTERM) to both monitor commands
6. Add stderr draining for adb process
7. Add database dispose method and cleanup

### Phase 3: Memory Bounds (For Long Sessions)
8. Add maximum size limits to EventCacheService
9. Implement LRU eviction or periodic cleanup
10. Consider result caching in EventCacheService with dirty flags

---

## Performance Testing Recommendations

1. **Memory profiling:** Run `dart run --observe` during extended monitoring sessions
2. **CPU profiling:** Use DevTools to identify hot paths
3. **Benchmark regex:** Compare static vs dynamic regex compilation overhead
4. **Load testing:** Simulate high-frequency event streams

---

## Metrics to Track

| Metric | Target | Current |
|--------|--------|---------|
| Memory after 1hr session | < 50MB | Unknown |
| CPU during idle monitoring | < 5% | Unknown |
| Event parse latency | < 1ms | Unknown |
| Startup time | < 500ms | Unknown |

---

## Related Documentation

- [Dart Performance Best Practices](https://dart.dev/tools/dart-devtools/performance)
- [Effective Dart: Performance](https://dart.dev/effective-dart)
