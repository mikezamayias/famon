#!/usr/bin/env bash
# =============================================================================
# filtered_session.sh — Filtered, keyboard-driven monitoring session
# =============================================================================
#
# A power-user workflow combining event filtering, parameter visibility
# controls, session stats, and smart suggestions.
#
# Prerequisites:
#   - dart pub global activate famon
#   - A connected Android device/emulator, or iOS Simulator running
#
# Usage:
#   ./example/filtered_session.sh
#
# =============================================================================

set -euo pipefail

# --- Show only e-commerce events, with stats and suggestions ----------------
#
# --show-only (-s)    Only display these event names (repeatable).
# --stats             Print session statistics every 30 seconds.
# --suggestions       Periodically suggest noisy events to hide.
#
# This combination is ideal for auditing a specific funnel while famon
# tells you what else is firing in the background.
famon monitor \
  --show-only purchase \
  --show-only add_to_cart \
  --show-only begin_checkout \
  --show-only view_item \
  --stats \
  --suggestions

# =============================================================================
# More filtering recipes
# =============================================================================

# --- Hide noisy automatic events --------------------------------------------
# --hide removes named events from the output (repeatable).
#
# famon monitor \
#   --hide screen_view \
#   --hide user_engagement \
#   --hide session_start

# --- Focus on specific parameters -------------------------------------------
# --show-only-params (-P) limits which parameter keys are printed.
# Applies to both event parameters and item arrays.
#
# famon monitor \
#   --show-only-params item_id \
#   --show-only-params price \
#   --show-only-params currency

# --- Separate global vs. event-specific parameters -------------------------
# --global-params (-g) classifies named params as "global" so they are
# grouped separately.  --hide-global-params starts with them hidden.
# Toggle visibility at runtime with the G key.
#
# famon monitor \
#   --global-params engagement_time_msec \
#   --global-params ga_session_id \
#   --global-params ga_session_number \
#   --hide-global-params

# --- Start with event parameters hidden ------------------------------------
# Useful when you only care about event names (not their payloads).
# Toggle at runtime with the E key.
#
# famon monitor --hide-event-params

# =============================================================================
# Keyboard shortcuts available during any session
# =============================================================================
#
#   ?   Show help
#   q   Quit
#   p   Toggle pause (events are still captured while paused)
#   c   Copy recent events to clipboard
#   s   Save all captured events to a JSON file
#   t   Show session statistics
#   l   Clear screen
#   g   Toggle global parameter visibility
#   e   Toggle event parameter visibility
#
# Disable shortcuts for non-interactive use:
#   famon monitor --no-shortcuts
