import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for event-related operations
class EventRemoteDataSource {
  final SupabaseClient _client;

  EventRemoteDataSource(this._client);

  // ✅ ADICIONAR: Método para buscar participantes do evento
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId) async {
    try {
      print('👥 [DataSource] Fetching participants for event: $eventId');
      
      final response = await _client
          .from('event_participants')
          .select('''
            user_id,
            status,
            users:user_id (
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('event_id', eventId)
          .eq('status', 'confirmed') // Só participantes confirmados
          .order('created_at', ascending: true);

      print('   ✅ Found ${response.length} participants');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('   ❌ Failed to fetch participants: $e');
      throw Exception('Failed to get event participants: $e');
    }
  }

  // ⚠️ STUB TEMPORÁRIO: Método getEventDetail (aguardando implementação do colega)
  Future<Map<String, dynamic>> getEventDetail(String eventId) async {
    print('⚠️ [STUB] getEventDetail called - using fake data');
    throw UnimplementedError('getEventDetail not implemented yet');
  }

  // ⚠️ STUB TEMPORÁRIO: Método updateEventDateTime
  Future<Map<String, dynamic>> updateEventDateTime(
    String eventId,
    DateTime startDateTime,
    DateTime? endDateTime,
  ) async {
    print('⚠️ [STUB] updateEventDateTime called - using fake data');
    throw UnimplementedError('updateEventDateTime not implemented yet');
  }

  // ⚠️ STUB TEMPORÁRIO: Método updateEventLocation
  Future<Map<String, dynamic>> updateEventLocation(
    String eventId,
    String locationName,
    String address,
    double latitude,
    double longitude,
  ) async {
    print('⚠️ [STUB] updateEventLocation called - using fake data');
    throw UnimplementedError('updateEventLocation not implemented yet');
  }

  // ⚠️ STUB TEMPORÁRIO: Método updateEventStatus
  Future<Map<String, dynamic>> updateEventStatus(
    String eventId,
    String status,
  ) async {
    print('⚠️ [STUB] updateEventStatus called - using fake data');
    throw UnimplementedError('updateEventStatus not implemented yet');
  }

  // ⚠️ STUB TEMPORÁRIO: Método isUserHost
  Future<bool> isUserHost(String eventId, String userId) async {
    print('⚠️ [STUB] isUserHost called - returning false');
    return false;
  }
}