/// Constants for the Firebase Analytics Monitor
library;

/// Threshold in milliseconds for grouping FA warning logs
const int faWarningGroupingThresholdMs = 500;

/// Default threshold for suggesting events to hide
const int defaultHideThreshold = 10;

/// Maximum number of top events to display in stats
const int maxTopEventsToDisplay = 15;

/// Maximum number of top events to display in formatted stats output
const int statsTopEventsLimit = 10;

/// Threshold for high-frequency event suggestions
const int highFrequencyThreshold = 50;

/// Timeout in seconds before showing troubleshooting tips
const int troubleshootingTimeoutSeconds = 12;

/// Duration before showing troubleshooting tips
const Duration troubleshootingTimeout = Duration(
  seconds: troubleshootingTimeoutSeconds,
);

/// Stats display interval in seconds
const int statsDisplayIntervalSeconds = 30;

/// Duration between stats display updates
const Duration statsDisplayInterval = Duration(
  seconds: statsDisplayIntervalSeconds,
);

/// Suggestions display interval in minutes
const int suggestionsDisplayIntervalMinutes = 5;

/// Duration between suggestions display updates
const Duration suggestionsDisplayInterval = Duration(
  minutes: suggestionsDisplayIntervalMinutes,
);

/// Number of top events to retrieve for suggestions
const int topEventsForSuggestions = 5;
