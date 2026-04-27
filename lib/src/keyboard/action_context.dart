import 'package:famon_core/famon_core.dart';
import 'package:mason_logger/mason_logger.dart';

/// Context passed to shortcut actions containing current application state.
///
/// This class provides actions with access to the current monitoring state,
/// including recent events, the event cache, and logging capabilities.
class ActionContext {
  /// Creates a new action context.
  const ActionContext({
    required this.recentEvents,
    required this.eventCache,
    required this.logger,
    this.isPaused = false,
    this.hideGlobalParams = false,
    this.hideEventParams = false,
    this.eventCountToExport = 10,
  });

  /// Recent analytics events captured during the session.
  ///
  /// This list is ordered from oldest to newest.
  final List<AnalyticsEvent> recentEvents;

  /// The event cache service for accessing session statistics.
  final EventCacheInterface eventCache;

  /// Logger for displaying output to the user.
  final Logger logger;

  /// Whether event streaming is currently paused.
  final bool isPaused;

  /// Whether global/default parameters are currently hidden from output.
  final bool hideGlobalParams;

  /// Whether event-specific parameters are currently hidden from output.
  final bool hideEventParams;

  /// Number of events to include when exporting to clipboard.
  final int eventCountToExport;

  /// Creates a copy of this context with optional new values.
  ActionContext copyWith({
    List<AnalyticsEvent>? recentEvents,
    EventCacheInterface? eventCache,
    Logger? logger,
    bool? isPaused,
    bool? hideGlobalParams,
    bool? hideEventParams,
    int? eventCountToExport,
  }) {
    return ActionContext(
      recentEvents: recentEvents ?? this.recentEvents,
      eventCache: eventCache ?? this.eventCache,
      logger: logger ?? this.logger,
      isPaused: isPaused ?? this.isPaused,
      hideGlobalParams: hideGlobalParams ?? this.hideGlobalParams,
      hideEventParams: hideEventParams ?? this.hideEventParams,
      eventCountToExport: eventCountToExport ?? this.eventCountToExport,
    );
  }
}
