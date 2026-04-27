# Performance and Memory Audit

This tool processes a continuous stream of logcat data. Resource efficiency matters in long-running sessions.

---

## Findings

### HIGH

#### 1. RegExp Compiled Per Parse Call in `_parseParams()`
**File:** `lib/src/services/log_parser_service.dart:221-240`

12 RegExp patterns compiled inside `_parseParams()` on every invocation. This method is called for every parsed event, sometimes recursively for items.

```dart
// CURRENT
Map<String, String> _parseParams(String paramsString) {
  final patterns = [
    RegExp(r'(\w+)=([^,\[\]{}]+)(?=[,\]}]|$)'),  // compiled every call
    RegExp(r'(\w+)=String\(([^)]*)\)'),
    // ... 10 more
  ];
}
```

Fix: move to `static final`:

```dart
static final List<RegExp> _paramPatterns = [
  RegExp(r'(\w+)=([^,\[\]{}]+)(?=[,\]}]|$)'),
  RegExp(r'(\w+)=String\(([^)]*)\)'),
  // ...
];
```

#### 2. RegExp Compiled Per Parse Call in `_parseItems()`
**File:** `lib/src/services/log_parser_service.dart:339-348`

Two patterns compiled on each call. Same fix: `static final`.

#### 3. RegExp Compiled Per Value Clean in `_cleanValue()`
**File:** `lib/src/services/log_parser_service.dart:385-394`

Six patterns compiled on every call. This method runs for every parameter value. Same fix: `static final`.

#### 4. Missing Signal Handlers
**File:** `lib/src/commands/monitor_command.dart`, `lib/src/cli/commands/filtered_monitor_command.dart`

No SIGINT/SIGTERM handlers — the adb process and open resources aren't cleaned up on Ctrl+C.

```dart
final sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
  process.kill();
  // cleanup resources
});
```

---

### MEDIUM

#### 5. RegExp Compiled Per Timestamp Parse
**File:** `lib/src/shared/log_timestamp_parser.dart:12`

Timestamp regex compiled on every call. Called for every event.

```dart
static final _timestampPattern = RegExp(
  r'(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d{3})',
);
```

#### 6. RegExp Compiled Per Logcat Line in MonitorCommand
**File:** `lib/src/commands/monitor_command.dart:228`

Firebase relevance check compiled for every line:

```dart
final isFirebaseRelated = RegExp(
  r'(FA|FA-SVC|FirebaseAnalytics|FirebaseCrashlytics)',
).hasMatch(line);
```

Move to `static final`.

#### 7. RegExp Compiled Per Validation in FilteredMonitorCommand
**File:** `lib/src/cli/commands/filtered_monitor_command.dart:379`

Parameter name validation regex compiled per call. Move to `static final`.

#### 8. Unbounded EventCache Growth
**File:** `lib/src/services/event_cache_service.dart`

`_uniqueEventNames` and `_eventCounts` grow unbounded. In multi-hour sessions, memory increases continuously.

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

`Isar.close()` is never called.

```dart
Future<void> dispose() async {
  await _isar?.close();
}
```

#### 10. stderr Not Consumed
**File:** `lib/src/commands/monitor_command.dart`, `lib/src/cli/commands/filtered_monitor_command.dart`

adb process stderr is not drained. Can cause buffer overflow if adb emits errors.

```dart
process.stderr.drain<void>();
```

---

### LOW

#### 11. Repeated `List.unmodifiable()` Allocations
**File:** `lib/src/services/event_cache_service.dart`

`allEventNames`, `getEventsByFrequency()`, `getTopEvents()` create new unmodifiable list wrappers on every call. Cache results with a dirty flag, or document that callers should cache.

#### 12. RegExp Per Search Call in EventCacheService
**File:** `lib/src/services/event_cache_service.dart:51`

User-provided regex compiled on each `searchEvents()` call. Acceptable since patterns vary, but could cache recently seen patterns.

#### 13. Chained `replaceAll()` in `_cleanValue()`
**File:** `lib/src/services/log_parser_service.dart:389-395`

Multiple `replaceAll()` calls create intermediate strings. Minor — consider single-pass cleaning if profiling shows impact.

---

## Implementation Priority

### Phase 1: Regex (high impact, low risk)
1. Static final patterns in `LogParserService` (`_parseParams`, `_parseItems`, `_cleanValue`)
2. Static final timestamp pattern in `LogTimestampParser`
3. Static final Firebase relevance pattern in `MonitorCommand`
4. Static final validation pattern in `FilteredMonitorCommand`

### Phase 2: Resource Management
1. Signal handlers (SIGINT/SIGTERM) in both monitor commands
2. Drain stderr for adb process
3. Database dispose method and cleanup on exit

### Phase 3: Memory Bounds (long sessions)
1. Max size limits in `EventCacheService`
2. LRU eviction or periodic cleanup
3. Result caching in `EventCacheService` with dirty flags

---

## Performance Testing

1. Memory profiling: `dart run --observe` during extended monitoring sessions
2. CPU profiling: DevTools to identify hot paths
3. Benchmark: static vs. dynamic regex compilation overhead
4. Load test: simulate high-frequency event streams

---

## Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Memory after 1hr session | < 50MB | Unknown |
| CPU during idle monitoring | < 5% | Unknown |
| Event parse latency | < 1ms | Unknown |
| Startup time | < 500ms | Unknown |

---

## References

- [Dart Performance Best Practices](https://dart.dev/tools/dart-devtools/performance)
- [Effective Dart](https://dart.dev/effective-dart)
