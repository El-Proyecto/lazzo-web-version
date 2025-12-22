import '../../domain/entities/event_detail.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_remote_data_source.dart';

/// Implementation of EventRepository using Supabase
class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource _remoteDataSource;

  EventRepositoryImpl(this._remoteDataSource);

  @override
  Future<EventDetail> getEventDetail(String eventId) async {
    final model = await _remoteDataSource.getEventDetail(eventId);
    return model.toEntity();
  }

  @override
  Future<bool> isUserHost(String eventId, String userId) async {
    return await _remoteDataSource.isUserHost(eventId, userId);
  }

  @override
  Future<EventDetail> updateEventDateTime(
    String eventId,
    DateTime startDateTime,
    DateTime? endDateTime,
  ) async {
    final model = await _remoteDataSource.updateEventDateTime(
      eventId,
      startDateTime,
      endDateTime,
    );
    return model.toEntity();
  }

  @override
  Future<EventDetail> updateEventLocation(
    String eventId,
    String locationName,
    String address,
    double latitude,
    double longitude,
  ) async {
    final model = await _remoteDataSource.updateEventLocation(
      eventId,
      locationName,
      address,
      latitude,
      longitude,
    );
    return model.toEntity();
  }

  @override
  Future<EventDetail> updateEventStatus(
    String eventId,
    EventStatus status,
  ) async {
    // Convert enum to string
    String statusString;
    switch (status) {
      case EventStatus.pending:
        statusString = 'pending';
        break;
      case EventStatus.confirmed:
        statusString = 'confirmed';
        break;
      case EventStatus.living:
        statusString = 'living';
        break;
      case EventStatus.recap:
        statusString = 'recap';
        break;
    }

    final model = await _remoteDataSource.updateEventStatus(
      eventId,
      statusString,
    );

    return model.toEntity();
  }

  @override
  Future<List<EventParticipantEntity>> getEventParticipants(
      String eventId) async {
    return await _remoteDataSource.getEventParticipants(eventId);
  }

  @override
  Future<EventDetail> extendEventTime(String eventId, int minutes) async {
    final model = await _remoteDataSource.extendEventTime(eventId, minutes);
    return model.toEntity();
  }

  @override
  Future<EventDetail> endEventNow(String eventId) async {
    final model = await _remoteDataSource.endEventNow(eventId);
    return model.toEntity();
  }
}
