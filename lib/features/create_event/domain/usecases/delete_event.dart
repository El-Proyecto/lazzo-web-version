import '../repositories/event_repository.dart';

/// Use case for deleting an event
/// Orchestrates event deletion with business rules
class DeleteEventUseCase {
  final EventRepository _repository;

  DeleteEventUseCase(this._repository);

  /// Execute event deletion with validation
  Future<void> execute(String eventId) async {
    // Business rule: validate event ID
    if (eventId.trim().isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }

    // Business rule: verify event exists before deletion
    final existingEvent = await _repository.getEventById(eventId);
    if (existingEvent == null) {
      throw ArgumentError('Event not found');
    }

    // TODO: Add business rule - only host can delete event
    // TODO: Add business rule - cannot delete events that are live/completed

    // Delegate to repository
    await _repository.deleteEvent(eventId);
  }
}
