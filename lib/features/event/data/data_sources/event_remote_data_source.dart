import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_detail_model.dart';

/// Remote data source for event operations
/// Handles all Supabase queries related to events
class EventRemoteDataSource {
  final SupabaseClient _supabaseClient;

  EventRemoteDataSource(this._supabaseClient);

  /// Get event details by ID
  /// Includes: RSVP counts, suggestion counts, location suggestion counts, poll count, host info
  Future<EventDetailModel> getEventDetail(String eventId) async {
    try {
      // Main event query
      final response = await _supabaseClient.from('events').select('''
            id,
            group_id,
            name,
            emoji,
            start_datetime,
            end_datetime,
            status,
            location_id,
            created_by,
            created_at
          ''').eq('id', eventId).single();

      // Get group name if exists
      String? groupName;
      if (response['group_id'] != null) {
        final groupResponse = await _supabaseClient
            .from('groups')
            .select('name')
            .eq('id', response['group_id'])
            .maybeSingle();

        if (groupResponse != null) {
          groupName = groupResponse['name'] as String?;
        }
      }

      // Get location details if exists
      String? locationName;
      String? locationAddress;
      double? locationLat;
      double? locationLng;

      if (response['location_id'] != null) {
        final locationResponse = await _supabaseClient
            .from('locations')
            .select('display_name, formatted_address, latitude, longitude')
            .eq('id', response['location_id'])
            .maybeSingle();

        if (locationResponse != null) {
          locationName = locationResponse['display_name'] as String?;
          locationAddress = locationResponse['formatted_address'] as String?;
          locationLat = (locationResponse['latitude'] as num?)?.toDouble();
          locationLng = (locationResponse['longitude'] as num?)?.toDouble();
        }
      }

      // Get RSVP counts from event_participants
      final rsvpCounts = await _supabaseClient
          .from('event_participants')
          .select('rsvp')
          .eq('pevent_id', eventId);

      int goingCount = 0;
      int notGoingCount = 0;

      // rsvp_status enum: pending, yes, no, maybe
      for (final rsvp in rsvpCounts) {
        final status = rsvp['rsvp'] as String;
        if (status == 'yes') {
          goingCount++;
        } else if (status == 'no') {
          notGoingCount++;
        }
      }

      // Build event detail with all data
      final eventData = <String, dynamic>{
        'id': response['id'],
        'group_id': response['group_id'],
        'group_name': groupName,
        'name': response['name'],
        'emoji': response['emoji'],
        'start_datetime': response['start_datetime'],
        'end_datetime': response['end_datetime'],
        'status': response['status'],
        'location_name': locationName,
        'location_address': locationAddress,
        'location_latitude': locationLat,
        'location_longitude': locationLng,
        'created_at': response['created_at'],
        'host_id': response['created_by'],
        'rsvp_going_count': goingCount,
        'rsvp_not_going_count': notGoingCount,
      };

      return EventDetailModel.fromJson(eventData);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get event detail: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get event detail: $e');
    }
  }

  /// Check if user is the event host
  Future<bool> isUserHost(String eventId, String userId) async {
    try {
      final response = await _supabaseClient
          .from('events')
          .select('created_by')
          .eq('id', eventId)
          .single();

      return response['created_by'] == userId;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check host status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check host status: $e');
    }
  }

  /// Update event date/time
  Future<EventDetailModel> updateEventDateTime(
    String eventId,
    DateTime startDateTime,
    DateTime? endDateTime,
  ) async {
    try {
      // Update the event
      await _supabaseClient
          .from('events')
          .update({
            'start_datetime': startDateTime.toIso8601String(),
            'end_datetime': endDateTime?.toIso8601String(),
          })
          .eq('id', eventId)
          .select()
          .single();

      // Return updated event detail
      return await getEventDetail(eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update event date/time: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update event date/time: $e');
    }
  }

  /// Update event location
  /// Creates/updates location entry and links to event
  Future<EventDetailModel> updateEventLocation(
    String eventId,
    String locationName,
    String address,
    double latitude,
    double longitude,
  ) async {
    try {
      // Get current event to check if it has a location_id
      final event = await _supabaseClient
          .from('events')
          .select('location_id, created_by')
          .eq('id', eventId)
          .single();

      final currentLocationId = event['location_id'] as String?;
      final createdBy = event['created_by'] as String;

      String locationId;

      if (currentLocationId != null) {
        // Update existing location
        await _supabaseClient.from('locations').update({
          'display_name': locationName,
          'formatted_address': address,
          'latitude': latitude,
          'longitude': longitude,
        }).eq('id', currentLocationId);

        locationId = currentLocationId;
      } else {
        // Create new location
        final locationResponse = await _supabaseClient
            .from('locations')
            .insert({
              'display_name': locationName,
              'formatted_address': address,
              'latitude': latitude,
              'longitude': longitude,
              'created_by': createdBy,
            })
            .select('id')
            .single();

        locationId = locationResponse['id'] as String;

        // Link location to event
        await _supabaseClient.from('events').update({
          'location_id': locationId,
        }).eq('id', eventId);
      }

      // Return updated event detail
      return await getEventDetail(eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update event location: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update event location: $e');
    }
  }

  /// Update event status
  Future<EventDetailModel> updateEventStatus(
    String eventId,
    String status,
  ) async {
    try {
      print('🔧 [DATA SOURCE] Updating event $eventId in Supabase');
      print('   🎯 New status value: "$status"');
      print('   📊 Building update payload: {status: $status}');

      // Execute update without select to avoid issues
      print('   🚀 Executing UPDATE query on events table...');
      await _supabaseClient
          .from('events')
          .update({'status': status}).eq('id', eventId);

      print('✅ [DATA SOURCE] Supabase UPDATE command executed');

      // Verify the update by fetching the event directly with a small delay
      await Future.delayed(const Duration(milliseconds: 100));

      print('🔍 [DATA SOURCE] Verifying update by fetching event...');
      final verifyResponse = await _supabaseClient
          .from('events')
          .select('id, name, status')
          .eq('id', eventId)
          .single();

      print('📊 [DATA SOURCE] Verification result:');
      print('   📌 Event ID: ${verifyResponse['id']}');
      print('   📝 Event Name: ${verifyResponse['name']}');
      print('   🎯 Current status in DB: "${verifyResponse['status']}"');

      if (verifyResponse['status'] != status) {
        print('⚠️ [DATA SOURCE] WARNING: Status mismatch!');
        print('   Expected: "$status"');
        print('   Got: "${verifyResponse['status']}"');
        throw Exception(
            'Status update failed: expected $status but got ${verifyResponse['status']}');
      }

      // Return updated event detail
      print('📦 [DATA SOURCE] Fetching full event detail...');
      final updatedEvent = await getEventDetail(eventId);
      print(
          '✅ [DATA SOURCE] Full event detail model status: "${updatedEvent.status}"');

      return updatedEvent;
    } on PostgrestException catch (e) {
      print('❌ [DATA SOURCE] PostgrestException: ${e.message}');
      print('   Code: ${e.code}');
      print('   Details: ${e.details}');
      throw Exception('Failed to update event status: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ [DATA SOURCE] Exception: $e');
      print('   Stack trace: $stackTrace');
      throw Exception('Failed to update event status: $e');
    }
  }
}
