import 'package:famon/src/constants.dart';
import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/shared/log_timestamp_parser.dart';

/// Callback type for when buffered FA warnings are ready to be flushed.
typedef FaWarningFlushCallback =
    void Function({
      required String? startTimestamp,
      required String? endTimestamp,
      required Map<String, String> parameters,
    });

/// Buffers FA invalid default parameter warnings and groups them by time.
///
/// Firebase Analytics can emit many "Invalid default event parameter type"
/// warnings in quick succession. This class groups them together to avoid
/// flooding the output with individual warnings.
///
/// Warnings within [faWarningGroupingThresholdMs] of each other are grouped.
/// When a gap is detected or [flush] is called, the buffered warnings are
/// emitted via the [onFlush] callback.
class FaWarningBuffer {
  /// Creates a new FaWarningBuffer.
  ///
  /// [onFlush] is called when buffered warnings should be output.
  FaWarningBuffer({required this.onFlush});

  /// Callback invoked when buffered warnings are ready to be flushed.
  final FaWarningFlushCallback onFlush;

  DateTime? _startTime;
  DateTime? _lastTime;
  String? _startTsStr;
  String? _lastTsStr;
  final Map<String, String> _params = {};

  /// Returns true if there are buffered warnings waiting to be flushed.
  bool get hasPending => _params.isNotEmpty;

  /// Adds an FA warning event to the buffer.
  ///
  /// If the time gap since the last warning exceeds the threshold,
  /// the buffer is flushed before adding the new warning.
  void add(AnalyticsEvent event) {
    final tsStr = event.rawTimestamp ?? event.displayTimestamp;
    final ts = parseLogcatTimestamp(tsStr);

    // Check if we should flush due to time gap
    if (_lastTime != null && ts != null) {
      final gap = ts.difference(_lastTime!).inMilliseconds;
      if (gap > faWarningGroupingThresholdMs) {
        flush();
      }
    }

    _startTime ??= ts;
    _lastTime = ts ?? _lastTime;
    _startTsStr ??= tsStr;
    _lastTsStr = tsStr;

    for (final entry in event.parameters.entries) {
      _params[entry.key] = entry.value;
    }
  }

  /// Flushes all buffered warnings via the [onFlush] callback.
  ///
  /// Does nothing if the buffer is empty.
  void flush() {
    if (_params.isEmpty) return;

    onFlush(
      startTimestamp: _startTsStr,
      endTimestamp: _lastTsStr,
      parameters: Map.unmodifiable(_params),
    );

    reset();
  }

  /// Resets the buffer, clearing all buffered warnings.
  void reset() {
    _startTime = null;
    _lastTime = null;
    _startTsStr = null;
    _lastTsStr = null;
    _params.clear();
  }
}
