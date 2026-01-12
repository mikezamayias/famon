import 'dart:io';

import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_models.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;

/// Database wrapper for Isar
///
/// Managed as a singleton by GetIt via @Singleton annotation
@Singleton()
class IsarDatabase {
  /// Creates a new IsarDatabase instance
  IsarDatabase();

  Isar? _isar;

  /// Gets the Isar database instance, initializing if needed
  Future<Isar> get db async {
    _isar ??= await _initDatabase();
    return _isar!;
  }

  Future<Isar> _initDatabase() async {
    // For pure Dart/CLI (non-Flutter) apps we need to initialize Isar Core
    // so the native library (e.g., libisar.dylib on macOS) is available.
    // This will download the appropriate binary if not present.
    await Isar.initializeIsarCore(download: true);

    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    final dbDir = path.join(homeDir, '.firebase_analytics_monitor');
    final dir = Directory(dbDir);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return Isar.open(
      [
        IsarAnalyticsEventSchema,
        IsarEventMetadataSchema,
        IsarSessionDataSchema,
      ],
      directory: dir.path,
      name: 'firebase_analytics_monitor',
    );
  }

  /// Closes the database connection.
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// Clears all data from the database.
  Future<void> clear() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
