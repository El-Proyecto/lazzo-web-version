import '../entities/event.dart';
import '../repositories/event_repository.dart';

/// Use case for updating an existing event
/// Orchestrates event update with business rules
class UpdateEventUseCase {
  final EventRepository _repository;

  UpdateEventUseCase(this._repository);

  /// Execute event update with validation
  Future<Event> execute({
    required String eventId,
    required String name,
    required String emoji,
    required String groupId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventLocation? location,
  }) async {
    // Business rule: validate event name
    if (name.trim().isEmpty) {
      throw ArgumentError('Event name cannot be empty');
    }

    // Business rule: validate end time if provided
    if (startDateTime != null && endDateTime != null) {
      if (endDateTime.isBefore(startDateTime)) {
        throw ArgumentError('End time must be after start time');
      }
    }

    // Get existing event to preserve fields not being updated
    final existingEvent = await _repository.getEventById(eventId);
    if (existingEvent == null) {
      throw ArgumentError('Event not found');
    }

    // Create updated event entity
    // CRITICAL: Use ValueWrapper for nullable fields to allow explicit clearing
    // This enables "Decide Later" functionality (null dates/location)
    final updatedEvent = existingEvent.copyWith(
      name: name.trim(),
      emoji: emoji,
      groupId: groupId,
      startDateTime: ValueWrapper(startDateTime),
      endDateTime: ValueWrapper(endDateTime),
      location: ValueWrapper(location),
    );

    // Delegate to repository
    return await _repository.updateEvent(updatedEvent);
  }
}
