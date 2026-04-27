# Parsing Firebase Analytics events fast: a regex factory with early-exit markers

If you've ever tried to watch Firebase Analytics events in real time on Android, you know the pain. You run `adb logcat -s FA FA-SVC`, stare at a wall of text, and try to spot your `purchase` event somewhere between system garbage, GC messages, and ActivityManager noise. Maybe you pipe it through `grep`, lose the parameter data, and end up adding `print` statements to your app instead.

I built [famon](https://github.com/mikezamayias/famon) -- a Dart CLI that monitors Firebase Analytics events from Android logcat and iOS console output in real time. The interesting engineering problem wasn't the CLI scaffolding or the pretty output. It was parsing. Specifically: how do you match Firebase Analytics log lines against 10+ regex patterns without turning your tool into a bottleneck on a stream that can easily push thousands of lines per second?

## The problem with naive matching

Firebase Analytics doesn't log in one format. It logs in *many* formats depending on the SDK version, logcat verbosity flags, and whether you're looking at Android or iOS. Here's a sample of what Android alone produces:

```
Logging event: origin=app,name=purchase,params=Bundle[{currency=USD, value=9.99}]
FA-SVC Logging event (FE): name=screen_view, params=Bundle[{screen_name=Home}]
I/FA: Event logged: add_to_cart, params=Bundle[{item_id=SKU_123}]
FA-SVC event_name:custom_event
```

A naive approach would be a single giant regex with alternation (`|`) across all formats. That's slow -- the regex engine backtracks through every alternative on every line. A slightly better approach is a list of patterns tried sequentially. But if you have 10 patterns and 99% of logcat lines aren't FA-related, you're running 10 regex evaluations on lines that will never match.

## The solution: early-exit markers + ordered pattern lists

The architecture in famon uses three layers of optimization that compound on each other.

### Layer 1: Early-exit markers

Before touching a single regex, the parser checks whether the line contains any Firebase Analytics marker at all:

```dart
static const _faMarkers = ['FA', 'Logging event', 'Event logged'];

bool _containsFaMarker(String line) {
  for (final marker in _faMarkers) {
    if (line.contains(marker)) {
      return true;
    }
  }
  return false;
}
```

`String.contains()` is a simple substring scan -- no regex engine, no backtracking, just a linear scan that short-circuits on the first hit. On a typical logcat stream where 95-99% of lines have nothing to do with Firebase Analytics, this eliminates almost all work before any regex is evaluated.

### Layer 2: Pre-compiled static patterns

Every regex is declared as `static final`, compiled once at class load time:

```dart
static final List<RegExp> _logPatterns = [
  // Pattern 1: Standard format (most common)
  RegExp(
    r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*Logging event: '
    r'origin=\w+,name=([^,]+),params=(Bundle\[.*\])',
  ),

  // Pattern 2: FA-SVC with "Logging event" format
  RegExp(
    r'(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}).*FA-SVC.*Logging event.*name=([^,\s]+).*params=(Bundle\[.*\])',
  ),

  // ... 8 more patterns
];
```

This avoids the cost of regex compilation on every call to `parse()`. In Dart, `RegExp` compilation is non-trivial -- each pattern gets compiled to an internal automaton. On a hot path called for every logcat line, this matters.

### Layer 3: Frequency-ordered evaluation

The patterns aren't listed randomly. They're ordered by expected frequency of occurrence:

1. **Standard format** (`origin=app,name=...`) -- most common in modern Firebase SDKs
2. **FA-SVC tagged** -- frequent in debug builds
3. **FA tagged** -- general Firebase Analytics logs
4. **FE/Event logged formats** -- native SDK auto-events
5. **Basic/legacy formats** -- older SDK versions

The parser short-circuits on the first successful match:

```dart
AnalyticsEvent? parse(String logLine) {
  if (logLine.isEmpty) return null;

  // Layer 1: early exit
  if (!_containsFaMarker(logLine)) {
    return null;
  }

  // Layer 2+3: pre-compiled patterns in frequency order
  for (final regex in _logPatterns) {
    final match = regex.firstMatch(logLine);
    if (match != null) {
      final event = _createAnalyticsEvent(match);
      if (event != null) return event;
    }
  }

  return null;
}
```

On average, the most common format matches on the first or second pattern. The long tail of legacy formats only gets evaluated for the rare lines that pass the marker check but don't match common patterns.

## The factory: platform-specific parsers

Android and iOS log completely different formats. Instead of cramming both into one parser with even more patterns, famon uses a factory that returns the right parser for the platform:

```dart
class LogParserFactory {
  LogParserInterface create(PlatformType platform) {
    return switch (platform) {
      PlatformType.android => LogParserService(logger: _logger),
      PlatformType.iosSimulator => IosLogParserService(logger: _logger),
      PlatformType.iosDevice => IosLogParserService(logger: _logger),
      PlatformType.auto => LogParserService(logger: _logger),
    };
  }
}
```

Each parser carries its own marker list and pattern set. The iOS parser checks for `FirebaseAnalytics` and `FIRAnalytics` markers instead of `FA`, and its patterns handle the `key (_abbrev) = value;` format that iOS uses instead of Android's `Bundle[{key=value}]`.

This separation keeps each parser focused and fast. Adding a new platform (say, Flutter web console logs) means adding a new parser class and a new case in the factory -- no risk of breaking existing parsers.

## Why this matters for performance

Consider the math. A busy Android device might push 500-2,000 logcat lines per second. Of those, maybe 1-5 are Firebase Analytics events.

**Without early-exit markers:** 2,000 lines x 10 patterns = 20,000 regex evaluations per second.

**With early-exit markers:** ~1,990 lines rejected by `String.contains()` (fast) + ~10 lines x ~1.5 average pattern evaluations = ~15 regex evaluations per second.

That's a ~1,300x reduction in regex work. The `contains()` checks are so cheap they barely register -- it's essentially free filtering.

## Extending the pattern set

Adding a new log format is straightforward:

1. Add the marker string to `_faMarkers` if it's new
2. Add the regex to `_logPatterns` at the position matching its expected frequency
3. The existing `_createAnalyticsEvent` method handles the rest, since all patterns use the same capture group structure: timestamp (group 1), event name (group 2), parameters (group 3)

The consistent capture group contract means new patterns just work with the existing parameter parser -- no new extraction logic needed.

## Try it

```bash
# Install
dart pub global activate famon

# Monitor Android
famon monitor

# Monitor iOS Simulator
famon monitor --platform ios-simulator

# Filter events
famon monitor --show-only screen_view,purchase
```

## Links

- **GitHub:** [github.com/mikezamayias/famon](https://github.com/mikezamayias/famon)
- **pub.dev:** [pub.dev/packages/famon](https://pub.dev/packages/famon)

---

*famon is MIT-licensed and welcomes contributions. If you've found a Firebase Analytics log format that famon doesn't parse, open an issue with a sample log line.*
