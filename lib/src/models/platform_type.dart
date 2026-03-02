/// Supported platform types for Firebase Analytics monitoring.
enum PlatformType {
  /// Android device or emulator via adb logcat.
  android,

  /// iOS Simulator via xcrun simctl log stream.
  iosSimulator,

  /// Physical iOS device via idevicesyslog.
  iosDevice,

  /// Auto-detect based on connected devices.
  auto;

  /// Human-readable display name for the platform.
  String get displayName => switch (this) {
        android => 'Android',
        iosSimulator => 'iOS Simulator',
        iosDevice => 'iOS Device',
        auto => 'Auto-detect',
      };

  /// CLI argument value for this platform.
  String get cliValue => switch (this) {
        android => 'android',
        iosSimulator => 'ios-simulator',
        iosDevice => 'ios-device',
        auto => 'auto',
      };

  /// Parse from CLI argument value.
  static PlatformType fromCliValue(String value) => switch (value) {
        'android' => android,
        'ios-simulator' => iosSimulator,
        'ios-device' => iosDevice,
        'auto' || '' => auto,
        _ => auto,
      };

  /// Whether this is an iOS platform.
  bool get isIos => this == iosSimulator || this == iosDevice;

  /// Whether this is an Android platform.
  bool get isAndroid => this == android;
}
