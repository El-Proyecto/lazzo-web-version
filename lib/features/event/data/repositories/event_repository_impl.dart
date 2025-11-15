import '../../domain/entities/event_detail.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_remote_data_source.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource _dataSource;

  EventRepositoryImpl(this._dataSource);

  // ✅ IMPLEMENTADO: Buscar participantes do evento
  @override
  Future<List<EventParticipantEntity>> getEventParticipants(String eventId) async {
    try {
      final data = await _dataSource.getEventParticipants(eventId);
      
      return data.map((json) {
        final userData = json['users'] as Map<String, dynamic>?;
        
        return EventParticipantEntity(
          userId: json['user_id'] as String,
          displayName: userData?['display_name'] as String? ?? 'Unknown',
          avatarUrl: userData?['avatar_url'] as String?,
          status: json['status'] as String,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get event participants: $e');
    }
  }

  // ⚠️ STUB TEMPORÁRIO: Outros métodos (aguardando implementação do colega)
  @override
  Future<EventDetail> getEventDetail(String eventId) async {
    try {
      print('⚠️ [STUB] getEventDetail called - delegating to data source');
      await _dataSource.getEventDetail(eventId);
      // Se chegar aqui, o colega implementou - mas por agora vai falhar
      throw UnimplementedError('getEventDetail not implemented yet');
    } catch (e) {
      // Retorna default value para não crashar
      print('⚠️ [STUB] getEventDetail failed: $e - returning default event');
      return EventDetail(
        id: eventId,
        name: 'Event (Loading...)',
        emoji: '📅',
        groupId: 'unknown',
        startDateTime: null,
        endDateTime: null,
        location: null,
        status: EventStatus.pending,
        createdAt: DateTime.now(),
        hostId: 'unknown',
        goingCount: 0,
        notGoingCount: 0,
      );
    }
  }

  @override
  Future<bool> isUserHost(String eventId, String userId) async {
    try {
      print('⚠️ [STUB] isUserHost called');
      return await _dataSource.isUserHost(eventId, userId);
    } catch (e) {
      print('⚠️ [STUB] isUserHost failed: $e - returning false');
      return false;
    }
  }

  @override
  Future<EventDetail> updateEventDateTime(
    String eventId,
    DateTime startDateTime,
    DateTime? endDateTime,
  ) async {
    try {
      print('⚠️ [STUB] updateEventDateTime called');
      await _dataSource.updateEventDateTime(eventId, startDateTime, endDateTime);
      throw UnimplementedError('updateEventDateTime not implemented yet');
    } catch (e) {
      print('⚠️ [STUB] updateEventDateTime failed: $e');
      rethrow;
    }
  }

  @override
  Future<EventDetail> updateEventLocation(
    String eventId,
    String locationName,
    String address,
    double latitude,
    double longitude,
  ) async {
    try {
      print('⚠️ [STUB] updateEventLocation called');
      await _dataSource.updateEventLocation(
        eventId,
        locationName,
        address,
        latitude,
        longitude,
      );
      throw UnimplementedError('updateEventLocation not implemented yet');
    } catch (e) {
      print('⚠️ [STUB] updateEventLocation failed: $e');
      rethrow;
    }
  }

  @override
  Future<EventDetail> updateEventStatus(
    String eventId,
    EventStatus status,
  ) async {
    try {
      print('⚠️ [STUB] updateEventStatus called');
      final statusString = status.toString().split('.').last;
      await _dataSource.updateEventStatus(eventId, statusString);
      throw UnimplementedError('updateEventStatus not implemented yet');
    } catch (e) {
      print('⚠️ [STUB] updateEventStatus failed: $e');
      rethrow;
    }
  }
}