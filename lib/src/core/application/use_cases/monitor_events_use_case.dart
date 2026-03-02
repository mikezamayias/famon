import 'package:famon/src/core/domain/entities/analytics_event.dart';
import 'package:famon/src/core/domain/repositories/event_repository.dart';
import 'package:famon/src/core/domain/value_objects/filter_criteria.dart';

/// Use case for monitoring analytics events with advanced filtering
class MonitorEventsUseCase {
  /// Creates a new [MonitorEventsUseCase].
  const MonitorEventsUseCase({
    required this.eventRepository,
    required this.eventMetadataRepository,
  });

  /// The repository for accessing analytics events.
  final EventRepository eventRepository;

  /// The repository for accessing event metadata.
  final EventMetadataRepository eventMetadataRepository;

  /// Stream filtered events in real-time
  Stream<AnalyticsEvent> execute({
    FilterCriteria? criteria,
    bool applyFrequencyFilters = true,
    bool applyManualParameters = true,
  }) async* {
    // Get hidden events from metadata to exclude them
    final hiddenEvents = await eventMetadataRepository.getEventMetadataList(
      isHidden: true,
    );
    final hiddenEventNames = hiddenEvents.map((e) => e.eventName).toList();

    // Combine user criteria with hidden events
    final effectiveCriteria =
        criteria?.copyWith(
          excludeEventNames: [
            ...criteria.excludeEventNames,
            ...hiddenEventNames,
          ],
        ) ??
        FilterCriteria(excludeEventNames: hiddenEventNames);

    // Apply frequency-based filtering if enabled
    var finalCriteria = effectiveCriteria;
    if (applyFrequencyFilters && effectiveCriteria.minFrequency != null) {
      final lowFrequencyEvents = await _getLowFrequencyEvents(
        effectiveCriteria.minFrequency!,
      );
      finalCriteria = effectiveCriteria.copyWith(
        excludeEventNames: [
          ...effectiveCriteria.excludeEventNames,
          ...lowFrequencyEvents,
        ],
      );
    }

    // Stream events with the final criteria
    await for (final event in eventRepository.watchEvents(
      criteria: finalCriteria,
    )) {
      // Apply manual parameters if enabled
      if (applyManualParameters) {
        final metadata = await eventMetadataRepository.getEventMetadata(
          event.eventName,
        );
        if (metadata != null) {
          // Add any custom manual parameters from metadata
          // This could be extended to support session-specific manual params
          yield event;
        } else {
          yield event;
        }
      } else {
        yield event;
      }
    }
  }

  /// Get events that have low frequency (below threshold)
  Future<List<String>> _getLowFrequencyEvents(double threshold) async {
    final allMetadata = await eventMetadataRepository.getEventMetadataList();
    return allMetadata
        .where((metadata) => metadata.frequency < threshold)
        .map((metadata) => metadata.eventName)
        .toList();
  }
}
