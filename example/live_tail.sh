#!/usr/bin/env bash
# =============================================================================
# live_tail.sh — Live tail Firebase Analytics events
# =============================================================================
#
# The simplest famon workflow: connect to a device and stream every
# Firebase Analytics event as it fires.
#
# Prerequisites:
#   - dart pub global activate famon
#   - A connected Android device/emulator, or iOS Simulator running
#
# Usage:
#   ./example/live_tail.sh
#
# =============================================================================

set -euo pipefail

# --- Basic live tail (auto-detects platform) --------------------------------
# Streams parsed FA events with color-coded output.
# Press ? for keyboard shortcuts, Q to quit.
famon monitor

# --- Target a specific platform ---------------------------------------------
# famon monitor --platform android        # Android device/emulator only
# famon monitor --platform ios-simulator   # iOS Simulator only
# famon monitor --platform ios-device      # Physical iOS device only

# --- Enable Analytics DebugView first ---------------------------------------
# Turns on DebugView for the given package so every event is logged
# immediately instead of being batched.  Also raises logcat verbosity.
# famon monitor --enable-debug com.example.myapp

# --- Verbose mode ------------------------------------------------------------
# Prints ALL Firebase Analytics / Crashlytics log lines, not just parsed
# events.  Useful for diagnosing why an event is not showing up.
# famon monitor --verbose

# --- Raw output (no formatting / grouping) -----------------------------------
# Prints parameter values exactly as they appear in the log stream,
# without the pretty table formatting.
# famon monitor --raw

# --- Disable color (for piping / CI) ----------------------------------------
# famon monitor --no-color
