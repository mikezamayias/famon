import 'package:famon_core/src/core/domain/entities/analytics_event.dart';
import 'package:famon_core/src/core/domain/entities/event_metadata.dart';
import 'package:famon_core/src/core/domain/repositories/event_repository.dart';

/// Use case for adding manual parameters to events for more precise monitoring
class AddManualParametersUseCase {
  /// Creates a new [AddManualParametersUseCase].
  const AddManualParametersUseCase({
    required this.eventRepository,
    required this.eventMetadataRepository,
  });

  /// The repository for accessing and saving analytics events.
  final EventRepository eventRepository;

  /// The repository for accessing and saving event metadata.
  final EventMetadataRepository eventMetadataRepository;

  /// Add manual parameters to a specific event type
  Future<void> addParametersToEventType(
    String eventName,
    Map<String, String> manualParameters,
  ) async {
    // Get existing metadata or create new one
    var metadata = await eventMetadataRepository.getEventMetadata(eventName);

    metadata ??= EventMetadata(
      eventName: eventName,
      totalCount: 0,
      firstSeen: DateTime.now(),
      lastSeen: DateTime.now(),
      frequency: 0,
      customTags: const ['manual_parameters'],
    );

    // Save the metadata (this would include the manual parameters logic)
    await eventMetadataRepository.saveEventMetadata(metadata);

    // Note: In a real implementation, you might want to store manual
    // parameters separately or as part of the metadata. For now, this
    // demonstrates the pattern.
  }

  /// Add manual parameters to a specific event instance
  Future<AnalyticsEvent> addParametersToEvent(
    AnalyticsEvent event,
    Map<String, String> manualParameters,
  ) async {
    // Create a new event with the manual parameters added
    final updatedEvent = event.copyWith(
      manualParameters: {...event.manualParameters, ...manualParameters},
    );

    // Save the updated event
    await eventRepository.saveEvent(updatedEvent);

    return updatedEvent;
  }

  /// Remove manual parameters from an event type
  Future<void> removeParametersFromEventType(
    String eventName,
    List<String> parameterKeys,
  ) async {
    final metadata = await eventMetadataRepository.getEventMetadata(eventName);

    if (metadata != null) {
      // Remove manual_parameters tag if no more manual parameters
      final updatedTags = metadata.customTags
          .where((tag) => tag != 'manual_parameters')
          .toList();

      final updatedMetadata = metadata.copyWith(customTags: updatedTags);

      await eventMetadataRepository.saveEventMetadata(updatedMetadata);
    }
  }

  /// Get all manual parameters for an event type
  Future<Map<String, String>> getManualParametersForEventType(
    String eventName,
  ) async {
    // Get metadata for future use when implementing manual parameters storage
    await eventMetadataRepository.getEventMetadata(eventName);

    // In a real implementation, manual parameters would be stored in metadata
    // For now, return empty map as placeholder
    return {};
  }

  /// List all event types that have manual parameters
  Future<List<String>> getEventTypesWithManualParameters() async {
    final allMetadata = await eventMetadataRepository.getEventMetadataList();

    return allMetadata
        .where((metadata) => metadata.customTags.contains('manual_parameters'))
        .map((metadata) => metadata.eventName)
        .toList();
  }
}
