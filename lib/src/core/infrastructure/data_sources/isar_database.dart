import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/database_directory_resolver.dart';
import 'package:firebase_analytics_monitor/src/core/infrastructure/data_sources/isar_models.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';

/// Database wrapper for Isar.
///
/// Managed as a singleton by GetIt via @Singleton annotation.
/// Uses `DatabaseDirectoryResolver` to determine the database location.
@Singleton()
class IsarDatabase {
  /// Creates a new IsarDatabase instance.
  ///
  /// The `directoryResolver` is used to determine the database directory.
  IsarDatabase(this._directoryResolver);

  final DatabaseDirectoryResolver _directoryResolver;

  /// The name used for the Isar database file.
  static const String databaseName = 'firebase_analytics_monitor';

  Isar? _isar;

  /// Gets the Isar database instance, initializing if needed.
  Future<Isar> get db async {
    _isar ??= await _initDatabase();
    return _isar!;
  }

  Future<Isar> _initDatabase() async {
    // For pure Dart/CLI (non-Flutter) apps we need to initialize Isar Core
    // so the native library (e.g., libisar.dylib on macOS) is available.
    // This will download the appropriate binary if not present.
    await Isar.initializeIsarCore(download: true);

    final dbDirectory = _directoryResolver.resolve();

    return Isar.open(
      [
        IsarAnalyticsEventSchema,
        IsarEventMetadataSchema,
        IsarSessionDataSchema,
      ],
      directory: dbDirectory,
      name: databaseName,
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
