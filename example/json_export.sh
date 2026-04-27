#!/usr/bin/env bash
# =============================================================================
# json_export.sh — Export captured events to JSON
# =============================================================================
#
# famon does not have a --json CLI flag, but it supports exporting events
# to a timestamped JSON file interactively via the "s" keyboard shortcut.
#
# This script shows two approaches:
#   1. Interactive export using the built-in save shortcut.
#   2. Piping raw output through jq for ad-hoc JSON conversion.
#
# Prerequisites:
#   - dart pub global activate famon
#   - jq (https://jqlang.github.io/jq/) for the piping approach
#   - A connected Android device/emulator, or iOS Simulator running
#
# Usage:
#   ./example/json_export.sh
#
# =============================================================================

set -euo pipefail

echo "=== Approach 1: Interactive JSON export ==="
echo ""
echo "Start monitoring and press 's' at any time to save all captured"
echo "events to a JSON file (famon_export_YYYY-MM-DD_HH-MM-SS.json)."
echo ""
echo "The exported JSON looks like:"
echo '  {'
echo '    "exportedAt": "2025-01-15T10:30:00.000Z",'
echo '    "totalEvents": 42,'
echo '    "events": ['
echo '      {'
echo '        "eventName": "screen_view",'
echo '        "timestamp": "2025-01-15T10:29:55.123Z",'
echo '        "parameters": { "screen_name": "HomeScreen", ... }'
echo '      }'
echo '    ]'
echo '  }'
echo ""
echo "Starting famon monitor — press 's' to save, 'q' to quit..."
echo ""

famon monitor

# =============================================================================
# Approach 2: Pipe raw output through jq
# =============================================================================
#
# Use --raw and --no-color to get unformatted output, then reshape with jq.
# This is useful for CI or scripted pipelines where you need structured data.
#
#   famon monitor --raw --no-color 2>/dev/null \
#     | grep -E '^\[' \
#     | jq -R 'split(" | ") | {time: .[0], event: .[1], params: .[2]}' \
#     > events.jsonl
#
# Tip: Use timeout or a background process + kill for unattended captures:
#
#   timeout 60 famon monitor --raw --no-color --no-shortcuts > capture.log 2>&1
#   # Then parse capture.log offline
