import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_detail_model.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../../../services/notification_service.dart';

/// Remote data source for event operations
/// Handles all Supabase queries related to events
class EventRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final NotificationService _notificationService;

  EventRemoteDataSource(this._supabaseClient)
      : _notificationService = NotificationService(_supabaseClient);

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

      // Send "Event Location Set" notification to all participants except host
      try {
        // Get event details for notification
        final eventResponse = await _supabaseClient
            .from('events')
            .select('name, emoji, created_by')
            .eq('id', eventId)
            .single();
        
        final eventName = eventResponse['name'] as String;
        final eventEmoji = eventResponse['emoji'] as String?;
        final hostUserId = eventResponse['created_by'] as String;
        
        // Get all participants except the host
        final participantsResponse = await _supabaseClient
            .from('event_participants')
            .select('user_id')
            .eq('pevent_id', eventId)
            .neq('user_id', hostUserId);
        
        // Send notification to each participant
        for (final participant in participantsResponse) {
          final participantId = participant['user_id'] as String;
          await _notificationService.sendEventLocationSet(
            recipientUserId: participantId,
            eventName: eventName,
            eventId: eventId,
            locationName: locationName,
            eventEmoji: eventEmoji,
          );
        }
      } catch (e) {
        // Don't fail location update if notification fails
      }

      // Return updated event detail
      return await getEventDetail(eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update event location: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update event location: $e');
    }
  }

  /// Calculate correct event status based on current time
  String _calculateEventStatus(
      DateTime? startDateTime, DateTime? endDateTime, String currentStatus) {
    if (startDateTime == null || endDateTime == null) {
      return currentStatus;
    }

    final now = DateTime.now().toUtc();
    final startUtc = startDateTime.toUtc();
    final endUtc = endDateTime.toUtc();

    if (now.isAfter(endUtc)) return 'recap';
    if (now.isAfter(startUtc) && now.isBefore(endUtc)) return 'living';
    if (currentStatus == 'draft' || currentStatus == 'pending') {
      return currentStatus;
    }

    return 'confirmed';
  }

  /// Update event status
  Future<EventDetailModel> updateEventStatus(
    String eventId,
    String status,
  ) async {
    try {
      // Get event dates to calculate correct status
      final event = await _supabaseClient
          .from('events')
          .select('start_datetime, end_datetime')
          .eq('id', eventId)
          .single();

      final startDateTime = event['start_datetime'] != null
          ? DateTime.parse(event['start_datetime'] as String)
          : null;
      final endDateTime = event['end_datetime'] != null
          ? DateTime.parse(event['end_datetime'] as String)
          : null;

      // Calculate correct status based on time
      String finalStatus = status;
      if (status == 'confirmed' || status == 'living' || status == 'recap') {
        finalStatus = _calculateEventStatus(startDateTime, endDateTime, status);
      }

      // Execute update without select to avoid issues
      await _supabaseClient
          .from('events')
          .update({'status': finalStatus}).eq('id', eventId);

      // Send "Event Date Set" notification when status changes to planning/confirmed
      if (finalStatus == 'planning' || finalStatus == 'confirmed') {
        try {
          // Get event details for notification
          final eventResponse = await _supabaseClient
              .from('events')
              .select('name, emoji, created_by, start_datetime')
              .eq('id', eventId)
              .single();
          
          final eventName = eventResponse['name'] as String;
          final eventEmoji = eventResponse['emoji'] as String?;
          final hostUserId = eventResponse['created_by'] as String;
          final startDateTimeStr = eventResponse['start_datetime'] as String?;
          
          if (startDateTimeStr != null) {
            final startDateTime = DateTime.parse(startDateTimeStr);
            final date = '${startDateTime.day}/${startDateTime.month}/${startDateTime.year}';
            final time = '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';
            
            // Get all participants except the host
            final participantsResponse = await _supabaseClient
                .from('event_participants')
                .select('user_id')
                .eq('pevent_id', eventId)
                .neq('user_id', hostUserId);
            
            // Send notification to each participant
            for (final participant in participantsResponse) {
              final participantId = participant['user_id'] as String;
              await _notificationService.sendEventDateSet(
                recipientUserId: participantId,
                eventName: eventName,
                eventId: eventId,
                date: date,
                time: time,
                eventEmoji: eventEmoji,
              );
            }
          }
        } catch (e) {
          // Don't fail status update if notification fails
        }
      }

      // Verify the update by fetching the event directly with a small delay
      await Future.delayed(const Duration(milliseconds: 100));

      final verifyResponse = await _supabaseClient
          .from('events')
          .select('id, name, status')
          .eq('id', eventId)
          .single();

      if (verifyResponse['status'] != finalStatus) {
        throw Exception(
            'Status update failed: expected $finalStatus but got ${verifyResponse['status']}');
      }

      // Return updated event detail
      final updatedEvent = await getEventDetail(eventId);

      return updatedEvent;
    } on PostgrestException catch (e) {
                        throw Exception('Failed to update event status: ${e.message}');
    } catch (e) {
                  throw Exception('Failed to update event status: $e');
    }
  }

  /// Get event participants (only those with rsvp='yes')
  Future<List<EventParticipantEntity>> getEventParticipants(
      String eventId) async {
    try {
      // Get participant user_ids - ONLY those with rsvp = 'yes'
      final participantsResponse = await _supabaseClient
          .from('event_participants')
          .select('user_id, rsvp')
          .eq('pevent_id', eventId)
          .eq('rsvp', 'yes');

      if (participantsResponse.isEmpty) {
        return [];
      }

      // Get user_ids
      final userIds = (participantsResponse as List)
          .map((p) => p['user_id'] as String)
          .toList();

      // Get users for those user_ids
      final usersResponse = await _supabaseClient
          .from('users')
          .select('id, name, avatar_url')
          .inFilter('id', userIds);

      // Create a map of userId -> user data
      final usersMap = {
        for (var user in usersResponse as List)
          user['id'] as String: user as Map<String, dynamic>,
      };

      
      // Combine participants with their user data and generate signed URLs for avatars
      final participants = await Future.wait(
        (participantsResponse as List).map((participant) async {
          final userId = participant['user_id'] as String;
          final userData = usersMap[userId];

          if (userData == null) {
            return EventParticipantEntity(
              userId: userId,
              displayName: 'Unknown User',
              avatarUrl: null,
              status: participant['rsvp'] as String? ?? 'pending',
            );
          }

          final displayName = userData['name'] as String? ?? 'Unknown User';
          final avatarPath = userData['avatar_url'] as String?;
          
          // Generate signed URL for avatar if path exists
          String? signedAvatarUrl;
          if (avatarPath != null && avatarPath.isNotEmpty) {
            try {
              signedAvatarUrl = await _supabaseClient.storage
                  .from('users-profile-pic')
                  .createSignedUrl(avatarPath, 3600); // 1 hour expiry
            } catch (e) {
              // Failed to generate signed URL, avatar will be null
            }
          }
          
          return EventParticipantEntity(
            userId: userId,
            displayName: displayName,
            avatarUrl: signedAvatarUrl,
            status: participant['rsvp'] as String? ?? 'pending',
          );
        }),
      );

      return participants;
    } on PostgrestException catch (e) {
                        throw Exception('Failed to get event participants: ${e.message}');
    } catch (e) {
                  throw Exception('Failed to get event participants: $e');
    }
  }

  /// Extend event end time by specified minutes
  Future<EventDetailModel> extendEventTime(String eventId, int minutes) async {
    try {
      // Get current event to calculate new end time
      final currentEvent = await getEventDetail(eventId);
      final currentEndTime = currentEvent.endDateTime;

      if (currentEndTime == null) {
        throw Exception('Event has no end time set');
      }

      // Calculate new end time
      final newEndTime = currentEndTime.add(Duration(minutes: minutes));

      // Update event in database
      await _supabaseClient
          .from('events')
          .update({'end_datetime': newEndTime.toIso8601String()})
          .eq('id', eventId);

      // CRITICAL: Send notifications to all participants (except host)
      try {
        final currentUserId = _supabaseClient.auth.currentUser?.id;
        final additionalHours = (minutes / 60).ceil();
        
        if (currentUserId != null) {
          // Get all participants of this event (except current user/host)
          final participants = await _supabaseClient
              .from('event_participants')
              .select('user_id')
              .eq('pevent_id', eventId)
              .neq('user_id', currentUserId);
          
          // Send notification to each participant
          for (final participant in participants) {
            final participantId = participant['user_id'] as String;
            
            await _notificationService.sendEventExtended(
              recipientUserId: participantId,
              eventName: currentEvent.name,
              eventId: eventId,
              additionalHours: additionalHours,
              eventEmoji: currentEvent.emoji,
            );
          }
        }
      } catch (e) {
        // Don't fail the extension if notification fails
      }

      // Return updated event
      return await getEventDetail(eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to extend event time: ${e.message}');
    } catch (e) {
      throw Exception('Failed to extend event time: $e');
    }
  }

  /// End event immediately (set end time to now)
  Future<EventDetailModel> endEventNow(String eventId) async {
    try {
      // Set end time to now
      final now = DateTime.now();

      await _supabaseClient
          .from('events')
          .update({'end_datetime': now.toIso8601String()})
          .eq('id', eventId);

      // Return updated event
      return await getEventDetail(eventId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to end event: ${e.message}');
    } catch (e) {
      throw Exception('Failed to end event: $e');
    }
  }
}
