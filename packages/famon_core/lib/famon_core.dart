/// Core library for Firebase Analytics event parsing, formatting,
/// and persistence.
///
/// This package provides the business logic, domain models, and services
/// used by the famon CLI and future Flutter GUI app.
library;

export 'src/constants.dart';
export 'src/core/application/services/event_filter_service.dart';
export 'src/core/application/use_cases/add_manual_parameters_use_case.dart';
export 'src/core/application/use_cases/data_export_import_use_case.dart';
export 'src/core/application/use_cases/export_data_use_case.dart';
export 'src/core/application/use_cases/import_data_use_case.dart';
export 'src/core/application/use_cases/monitor_events_use_case.dart';
export 'src/core/domain/entities/analytics_event.dart';
export 'src/core/domain/entities/event_metadata.dart';
export 'src/core/domain/entities/monitoring_session.dart';
export 'src/core/domain/repositories/data_export_repository.dart';
export 'src/core/domain/repositories/event_repository.dart';
export 'src/core/domain/value_objects/event_statistics.dart';
export 'src/core/domain/value_objects/filter_criteria.dart';
export 'src/core/domain/value_objects/session_statistics.dart';
export 'src/core/infrastructure/data_sources/database_directory_resolver.dart';
export 'src/core/infrastructure/data_sources/isar_database.dart';
export 'src/core/infrastructure/data_sources/isar_models.dart';
export 'src/core/infrastructure/repositories/isar_data_export_repository.dart';
export 'src/core/infrastructure/repositories/isar_event_metadata_repository.dart';
export 'src/core/infrastructure/repositories/isar_event_repository.dart';
export 'src/core_injection.dart';
export 'src/exceptions/parsing_exception.dart';
export 'src/models/event_summary.dart';
export 'src/models/platform_type.dart';
export 'src/models/session_stats.dart';
export 'src/services/event_cache_service.dart';
export 'src/services/event_formatter_service.dart';
export 'src/services/fa_warning_buffer.dart';
export 'src/services/interfaces/event_cache_interface.dart';
export 'src/services/interfaces/log_parser_interface.dart';
export 'src/services/interfaces/log_source_interface.dart';
export 'src/services/ios_log_parser_service.dart';
export 'src/services/log_parser_factory.dart';
export 'src/services/log_parser_service.dart';
export 'src/services/log_source_factory.dart';
export 'src/shared/log_timestamp_parser.dart';
export 'src/utils/event_filter_utils.dart';
