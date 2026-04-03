import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;

/// Resolves and creates the database directory for the application.
///
/// This class handles platform-specific home directory resolution and
/// ensures the database directory exists before use.
@injectable
class DatabaseDirectoryResolver {
  /// The name of the application directory within the user's home.
  static const String appDirectoryName = '.firebase_analytics_monitor';

  /// Resolves the database directory path.
  ///
  /// Returns the path to the database directory, creating it if necessary.
  /// Falls back to current directory if home directory cannot be determined.
  String resolve() {
    final homeDir = _resolveHomeDirectory();
    final dbDir = path.join(homeDir, appDirectoryName);

    _ensureDirectoryExists(dbDir);

    return dbDir;
  }

  /// Resolves the user's home directory based on platform.
  ///
  /// Checks HOME (Unix/macOS) and USERPROFILE (Windows) environment variables.
  /// Falls back to current directory if neither is set.
  String _resolveHomeDirectory() {
    return Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
  }

  /// Ensures the specified directory exists, creating it if necessary.
  void _ensureDirectoryExists(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }
}
