# 🔥 Firebase Analytics Monitor (famon)

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A powerful command-line tool for real-time monitoring and filtering of Firebase Analytics events from Android and iOS. Perfect for developers and QA engineers working with Firebase Analytics implementations.

## ✨ Features

- **🔍 Real-time monitoring**: Stream Firebase Analytics events as they happen
- **📱 Multi-platform support**: Works with Android, iOS Simulator, and iOS devices
- **🎯 Smart filtering**: Hide noisy events or show only specific ones
- **🎨 Beautiful output**: Colorized, well-formatted event display with emoji icons
- **📊 Smart suggestions**: Get recommendations for filtering based on session data
- **📈 Session statistics**: Track event frequency and patterns
- **⚡ Event parsing**: Comprehensive parsing of parameters and item arrays
- **🔄 Auto-detection**: Automatically detects connected devices/simulators
- **🛠 Developer-friendly**: Designed for debugging and analytics validation

---

## 🚀 Installation

### Global Installation via Pub

```bash
dart pub global activate firebase_analytics_monitor
```

### Local Development Installation

```bash
dart pub global activate --source=path <path to this package>
```

### From Source

```bash
git clone https://github.com/mikezamayias/firebase_analytics_monitor.git
cd firebase_analytics_monitor
dart pub get
dart compile exe bin/famon.dart -o famon
# Move famon to your PATH
```

## 📋 Prerequisites

### Android

- ✅ Android SDK platform-tools installed
- ✅ `adb` command available in your PATH
- ✅ Android device or emulator connected
- ✅ USB debugging enabled on your device
- ✅ App with Firebase Analytics running

Verify your Android setup:

```bash
adb devices  # Should show your connected device
adb logcat -s FA-SVC | head  # Should show Firebase Analytics logs
```

### iOS Simulator

- ✅ Xcode installed with Command Line Tools
- ✅ `xcrun` available in your PATH
- ✅ iOS Simulator running
- ✅ App with Firebase Analytics debug mode enabled

Verify your iOS Simulator setup:

```bash
xcrun simctl list booted  # Should show running simulator
```

### iOS Device

- ✅ libimobiledevice installed (`brew install libimobiledevice`)
- ✅ `idevicesyslog` available in your PATH
- ✅ iOS device connected via USB
- ✅ Device trusted to this computer
- ✅ App with Firebase Analytics debug mode enabled

Verify your iOS device setup:

```bash
idevice_id -l  # Should show connected device UDID
```

### iOS Firebase Analytics Debug Mode

To see Firebase Analytics logs on iOS, enable debug mode in your app:

1. **Xcode Scheme Arguments**: Add `-FIRAnalyticsDebugEnabled` to:
   Product > Scheme > Edit Scheme > Run > Arguments > Arguments Passed On Launch

2. **Or programmatically**:
   ```swift
   // In your app's launch code
   UserDefaults.standard.set(true, forKey: "/google/firebase/debug_mode")
   ```

## 🎯 Usage

### Basic Monitoring

Monitor all Firebase Analytics events (auto-detects platform):

```bash
famon monitor
```

### Platform Selection

Monitor specific platforms:

```bash
# Android device/emulator
famon monitor --platform android

# iOS Simulator
famon monitor --platform ios-simulator

# iOS physical device
famon monitor --platform ios-device

# Auto-detect (default)
famon monitor --platform auto
```

### Filter Events

Hide specific noisy events:

```bash
famon monitor --hide screen_view --hide _vs
```

Show only specific events:

```bash
famon monitor --show-only my_event --show-only another_event
# or using short form:
famon monitor -s my_event -s another_event
```

### Advanced Options

Monitor with smart suggestions and statistics:

```bash
famon monitor --suggestions --stats
```

Disable colors (useful for CI/CD or logging):

```bash
famon monitor --no-color
```

Verbose mode (shows all Firebase-related logs):

```bash
famon monitor --verbose
```

Raw output (unformatted parameter values):

```bash
famon monitor --raw
```

### Get Help

```bash
famon help           # Detailed help with examples
famon --help         # Basic usage information
famon --version      # Show version
```

## 📊 Example Output

```text
🔥 Firebase Analytics Monitor Started
📱 Connecting to adb logcat...
Press Ctrl+C to stop monitoring

[12-25 10:30:45.123] my_custom_event
  Parameters:
    param_one: value1
    param_two: value2

[12-25 10:31:15.456] another_event
  Parameters:
    screen_name: SomeScreen
    screen_class: MainActivity

💡 Smart Suggestions:
   Most frequent events: screen_view, _vs, app_update, user_engagement
   Consider hiding: screen_view, _vs
   Use: famon monitor --hide screen_view --hide _vs

📊 Session Stats:
   Unique Events: 8
   Total Events: 45
```


## 🔧 Command Reference

### Monitor Command

```bash
famon monitor [OPTIONS]
```

**Options:**

- `-p, --platform`: Target platform (`android`, `ios-simulator`, `ios-device`, `auto`)
- `--hide EVENT_NAME`: Hide specific event names (can be used multiple times)
- `-s, --show-only EVENT_NAME`: Only show specified events (can be used multiple times)
- `--no-color`: Disable colored output
- `--suggestions`: Show smart filtering suggestions based on session data
- `--stats`: Display session statistics periodically
- `-r, --raw`: Print raw parameter values without formatting
- `-V, --verbose`: Stream all Firebase Analytics/Crashlytics log lines
- `-D, --enable-debug PACKAGE`: Enable Analytics debug for a package (Android only)
- `--raise-log-levels`: Raise log levels to VERBOSE before monitoring
- `--help`: Show help for the monitor command

### Global Options

- `-v, --version`: Show version information
- `--verbose`: Enable verbose logging
- `--help`: Show general help

## 🧪 Testing Your Setup

1. **Test adb connection:**

   ```bash
   adb devices
   ```

2. **Test Firebase Analytics logs:**

   ```bash
   adb logcat -s FA-SVC | head -20
   ```

3. **Test with sample events:**
   - Open your app with Firebase Analytics
   - Navigate through screens or trigger events
   - Run `famon monitor` to see events in real-time

## 🐛 Troubleshooting

### Android Issues

#### "adb: command not found"

- Install Android SDK platform-tools
- Add platform-tools to your PATH

#### "No devices found"

- Connect your Android device via USB
- Enable USB debugging in Developer Options
- Try `adb kill-server && adb start-server`

#### "Permission denied" errors

- Check USB debugging permissions on device
- Try different USB cable or port

### iOS Simulator Issues

#### "xcrun: command not found"

- Install Xcode Command Line Tools: `xcode-select --install`

#### "No booted simulator found"

- Start an iOS Simulator from Xcode or: `xcrun simctl boot "iPhone 15"`
- Verify with: `xcrun simctl list booted`

#### "No Firebase Analytics logs appearing"

- Enable Firebase Analytics debug mode (see Prerequisites)
- Check that your app is running in the simulator
- Try: `xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "firebase"'`

### iOS Device Issues

#### "idevicesyslog: command not found"

- Install libimobiledevice: `brew install libimobiledevice`

#### "No device found"

- Connect your iOS device via USB
- Trust the computer on your device when prompted
- Verify with: `idevice_id -l`

#### "Could not connect to device"

- Make sure the device is unlocked
- Try unplugging and reconnecting
- Restart the usbmuxd service: `sudo launchctl stop com.apple.usbmuxd`

### General Issues

### "No Firebase Analytics events"

- Ensure your app has Firebase Analytics integrated
- Check that events are being sent (may have delays)
- Verify Firebase Analytics is properly configured
- **iOS**: Enable debug mode with `-FIRAnalyticsDebugEnabled`

### "Not all event parameters are showing"

If you're seeing events but missing parameters, this could be due to:

1. **Log format variations**: Firebase Analytics uses different log formats
2. **Parameter parsing issues**: Complex parameter structures may need adjustment

**To debug parameter parsing:**

```bash
# First, check the raw Firebase Analytics logs
adb logcat -s FA-SVC | head -10

# Look for patterns like:
# Logging event: origin=app,name=EVENT_NAME,params=Bundle[{param1=value1, param2=value2}]
```

**Common log formats supported:**

- `Logging event: origin=app,name=EVENT_NAME,params=Bundle[{...}]`
- `Event logged: EVENT_NAME params:Bundle[{...}]`
- `FA-SVC event_name:EVENT_NAME`

**If parameters are still missing:**

1. Check if the Bundle format in your logs matches the expected patterns
2. Some newer Firebase SDK versions may use different formats
3. Parameters with special characters or nested objects may need additional parsing

**Example of expected vs actual log format:**

Expected:

```text
Logging event: origin=app,name=view_cart,params=Bundle[{value=0, currency=GBP, login_mode=email_login}]
```

If your logs look different, please open an issue with a sample log line for format support.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
git clone https://github.com/mikezamayias/firebase_analytics_monitor.git
cd firebase_analytics_monitor
dart pub get
dart pub run build_runner build  # Generate model files
```

### Running Tests

```bash
dart test                           # Run all tests
dart test --coverage=coverage      # Run with coverage
dart pub run test                  # Alternative test command
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov):

```bash
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
```

---

[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
