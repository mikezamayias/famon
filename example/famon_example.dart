// ignore_for_file: avoid_print

/// Firebase Analytics Monitor (famon) - CLI Usage Examples
///
/// This file demonstrates how to use the `famon` command-line tool to monitor
/// Firebase Analytics events in real-time.
///
/// ## Installation
///
/// Install globally via pub.dev:
/// ```bash
/// dart pub global activate famon
/// ```
///
/// ## Basic Usage
///
/// Start monitoring Firebase Analytics events from a connected Android device:
/// ```bash
/// famon monitor
/// ```
///
/// ## Command Options
///
/// ### Platform Selection
/// ```bash
/// # Auto-detect platform (default)
/// famon monitor --platform auto
///
/// # Target Android specifically
/// famon monitor --platform android
///
/// # Target iOS Simulator
/// famon monitor --platform ios-simulator
///
/// # Target physical iOS device
/// famon monitor --platform ios-device
/// ```
///
/// ### Event Filtering
/// ```bash
/// # Hide specific events
/// famon monitor --hide screen_view --hide app_open
///
/// # Show only specific events
/// famon monitor --show-only purchase --show-only add_to_cart
/// ```
///
/// ### Output Options
/// ```bash
/// # Disable colored output
/// famon monitor --no-color
///
/// # Raw output without formatting
/// famon monitor --raw
///
/// # Verbose mode (show all FA logs)
/// famon monitor --verbose
/// ```
///
/// ### Debug Mode
/// ```bash
/// # Enable analytics debug for a package
/// famon monitor --enable-debug com.example.myapp
///
/// # Raise log levels for more detail
/// famon monitor --raise-log-levels
/// ```
///
/// ### Session Features
/// ```bash
/// # Show periodic statistics
/// famon monitor --stats
///
/// # Show smart suggestions
/// famon monitor --suggestions
/// ```
///
/// ## Interactive Keyboard Shortcuts
///
/// While monitoring, use these shortcuts:
/// - `?` - Show help
/// - `q` - Quit
/// - `p` - Toggle pause
/// - `c` - Copy recent events to clipboard
/// - `s` - Save events to file
/// - `t` - Show statistics
/// - `l` - Clear screen
///
/// ## Requirements
///
/// - **Android**: Android SDK platform-tools with `adb` in PATH
/// - **iOS Simulator**: Xcode with simulator tools
/// - **iOS Device**: Xcode with device support and valid provisioning
library;

import 'dart:io';

/// Example showing how to run famon programmatically.
///
/// This demonstrates running the CLI tool from Dart code, which can be useful
/// for integration testing or automation scenarios.
void main() async {
  print('Firebase Analytics Monitor (famon) - Example');
  print('');
  print('This is a CLI tool. To use it, run:');
  print('');
  print('  dart pub global activate famon');
  print('  famon monitor');
  print('');
  print('For help, run:');
  print('');
  print('  famon --help');
  print('  famon monitor --help');
  print('');

  // Example: Check if famon is available
  final result = await Process.run('famon', ['--version'], runInShell: true);
  if (result.exitCode == 0) {
    print('Installed version: ${result.stdout.toString().trim()}');
  } else {
    print(
      'famon is not installed. Install with: dart pub global activate famon',
    );
  }
}
