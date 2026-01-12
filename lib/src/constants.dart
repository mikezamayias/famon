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

/// Stats display interval in seconds
const int statsDisplayIntervalSeconds = 30;

/// Suggestions display interval in minutes
const int suggestionsDisplayIntervalMinutes = 2;

/// Timeout in seconds for adb connection
const int adbConnectionTimeoutSeconds = 30;
