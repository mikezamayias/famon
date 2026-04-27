/// Utility class for event filtering operations
class EventFilterUtils {
  // Private constructor to prevent instantiation
  EventFilterUtils._();

  /// Check if an event should be skipped based on hide/show filters
  ///
  /// Returns true if the event should be skipped (not displayed)
  ///
  /// [eventName] - The name of the event to check
  /// [hideEvents] - List of event names to hide
  /// [showOnlyEvents] - If non-empty, only show events in this list
  static bool shouldSkipEvent(
    String eventName,
    List<String> hideEvents,
    List<String> showOnlyEvents,
  ) {
    // If show-only is specified, only show those events
    if (showOnlyEvents.isNotEmpty) {
      return !showOnlyEvents.contains(eventName);
    }

    // If hide is specified, skip those events
    if (hideEvents.isNotEmpty) {
      return hideEvents.contains(eventName);
    }

    return false;
  }

  /// Check if an event should be skipped based on hide/show and frequency
  /// filters.
  ///
  /// Returns true if the event should be skipped (not displayed)
  ///
  /// [eventName] - The name of the event to check
  /// [hideEvents] - List of event names to hide
  /// [showOnlyEvents] - If non-empty, only show events in this list
  /// [eventFrequency] - The frequency count of this event (optional)
  /// [minFrequency] - Minimum frequency threshold (optional)
  /// [maxFrequency] - Maximum frequency threshold (optional)
  static bool shouldSkipEventWithFrequency(
    String eventName,
    List<String> hideEvents,
    List<String> showOnlyEvents, {
    int? eventFrequency,
    int? minFrequency,
    int? maxFrequency,
  }) {
    // First check basic hide/show filters
    if (shouldSkipEvent(eventName, hideEvents, showOnlyEvents)) {
      return true;
    }

    // Then check frequency filters if provided
    if (eventFrequency != null) {
      if (minFrequency != null && eventFrequency < minFrequency) {
        return true;
      }
      if (maxFrequency != null && eventFrequency > maxFrequency) {
        return true;
      }
    }

    return false;
  }
}
