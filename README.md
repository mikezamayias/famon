# famon - Firebase Analytics Monitor

[![pub package][pub_badge]][pub_link]
[![codecov][coverage_badge]][coverage_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

CLI tool for real-time monitoring of Firebase Analytics events from Android and iOS.

## Features

- Stream events as they happen
- Android, iOS Simulator, and iOS device support
- Filter by event name (hide or show-only)
- Colorized, formatted output
- Session statistics and filter suggestions
- Full parameter and item array parsing
- Auto-detects connected devices/simulators

---

## Package split

`famon` is the terminal interface. It owns command-line arguments, terminal output, keyboard shortcuts, clipboard/file integrations, logging, and process lifecycle wiring.

`famon_core` owns reusable analytics behavior: log parsing, event models, filtering, persistence, import/export, and monitoring primitives. Shared behavior should move into `famon_core` when it is useful outside terminal rendering.

## Roadmap

Short-term priorities:

- Keep `famon` focused on terminal monitoring, filtering, and developer workflow.
- Keep `famon_core` focused on reusable parsing, filtering, persistence, and import/export behavior.
- Improve cross-platform parser parity for Android, iOS Simulator, and iOS device logs.
- Tighten release automation and package archive hygiene.
- Clarify public API stability for `famon_core`.

## Installation

```bash
dart pub global activate famon
```

**From source:**

```bash
git clone https://github.com/mikezamayias/famon.git
cd famon
dart pub get
dart compile exe bin/famon.dart -o famon
# Move famon to your PATH
```

## Prerequisites

### Android

- Android SDK platform-tools + `adb` in PATH
- Android device or emulator connected with USB debugging enabled

```bash
adb devices                        # verify connection
adb logcat -s FA-SVC | head        # verify Firebase logs
```

### iOS Simulator

- Xcode + Command Line Tools (`xcrun` in PATH)
- Simulator running with Firebase Analytics debug mode enabled

```bash
xcrun simctl list booted
```

### iOS Device

- `idevicesyslog` installed (`brew install libimobiledevice`)
- Device connected via USB and trusted

```bash
idevice_id -l
```

### Enabling Firebase Analytics debug mode on iOS

Add `-FIRAnalyticsDebugEnabled` to your scheme's launch arguments (Product > Scheme > Edit Scheme > Run > Arguments), or set it programmatically:

```swift
UserDefaults.standard.set(true, forKey: "/google/firebase/debug_mode")
```

## Usage

```bash
famon monitor                          # auto-detect platform
famon monitor --platform android
famon monitor --platform ios-simulator
famon monitor --platform ios-device

famon monitor --hide screen_view --hide _vs
famon monitor --show-only my_event -s another_event

famon monitor --suggestions --stats
famon monitor --no-color
famon monitor --verbose
famon monitor --raw
```

### Issue reporting

```bash
famon issue    # collects system info and opens a pre-filled bug report
```

## Command reference

### `famon monitor`

| Option | Description |
|---|---|
| `-p, --platform` | `android`, `ios-simulator`, `ios-device`, `auto` |
| `--hide EVENT` | Hide event by name (repeatable) |
| `-s, --show-only EVENT` | Show only named events (repeatable) |
| `--no-color` | Disable color output |
| `--suggestions` | Show filter suggestions from session data |
| `--stats` | Show session statistics periodically |
| `-r, --raw` | Raw parameter values, no formatting |
| `-V, --verbose` | Stream all Firebase/Crashlytics log lines |
| `-D, --enable-debug PKG` | Enable Analytics debug for a package (Android only) |
| `--raise-log-levels` | Raise log levels to VERBOSE before monitoring |

## Example output

```text
[12-25 10:30:45.123] my_custom_event
  Parameters:
    param_one: value1
    param_two: value2

[12-25 10:31:15.456] another_event
  Parameters:
    screen_name: SomeScreen
    screen_class: MainActivity

Smart Suggestions:
   Most frequent: screen_view, _vs, app_update, user_engagement
   Use: famon monitor --hide screen_view --hide _vs

Session Stats:
   Unique Events: 8
   Total Events: 45
```

## Troubleshooting

### Android

**`adb: command not found`** — Install Android SDK platform-tools and add to PATH.

**No devices found** — Enable USB debugging, try `adb kill-server && adb start-server`.

**Permission denied** — Check USB debugging permissions or try a different cable/port.

### iOS Simulator

**`xcrun: command not found`** — Run `xcode-select --install`.

**No booted simulator** — `xcrun simctl boot "iPhone 15"`, verify with `xcrun simctl list booted`.

**No Firebase logs** — Enable debug mode (see Prerequisites), verify app is running.

### iOS Device

**`idevicesyslog: command not found`** — `brew install libimobiledevice`.

**No device found** — Trust the computer when prompted, verify with `idevice_id -l`.

**Could not connect** — Unlock device, unplug/replug, or restart usbmuxd: `sudo launchctl stop com.apple.usbmuxd`.

### No events appearing

- Confirm Firebase Analytics is integrated and debug mode is active
- iOS events may have delays
- Run `famon monitor --platform <platform> --verbose` to check raw Firebase log output

### Missing parameters

Check that your log format matches one of the supported patterns:

```text
Logging event: origin=app,name=EVENT_NAME,params=Bundle[{param1=value1, param2=value2}]
Event logged: EVENT_NAME params:Bundle[{...}]
FA-SVC event_name:EVENT_NAME
[Firebase/Analytics][I-ACS023073] Debug mode is enabled. Marking event as debug and real-time. Event name, parameters: EVENT_NAME, {
    param1 = value1;
}
```

If your logs look different, open an issue with a sample line.

## Contributing

Open an issue before large changes. For small fixes, PRs are welcome.

```bash
git clone https://github.com/mikezamayias/famon.git
cd famon
dart pub get
dart pub run build_runner build
dart test
dart test --coverage=coverage
```

Coverage report:

```bash
genhtml coverage/lcov.info -o coverage/
open coverage/index.html
```

---

[pub_badge]: https://img.shields.io/pub/v/famon.svg
[pub_link]: https://pub.dev/packages/famon
[coverage_badge]: https://codecov.io/gh/mikezamayias/famon/branch/main/graph/badge.svg
[coverage_link]: https://codecov.io/gh/mikezamayias/famon
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
