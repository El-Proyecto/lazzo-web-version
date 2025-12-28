import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_history.dart';
import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_data_source.dart';
import '../models/event_original_model.dart';
import '../models/event_history_model.dart';
import '../models/location_model.dart';
import '../../../../services/notification_service.dart';

/// Implementation of EventRepository using Supabase

class EventRepositoryImpl implements EventRepository {
  final EventDataSource _dataSource;
  final SupabaseClient _client;
  final NotificationService _notificationService;

  EventRepositoryImpl(SupabaseClient client)
      : _dataSource = EventDataSource(client),
        _client = client,
        _notificationService = NotificationService(client);

  /// Get current authenticated user ID
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Event> createEvent(Event event) async {
    try {
      final userId = _currentUserId;

      if (userId == null || userId.isEmpty) {
        throw Exception('User must be authenticated to create events');
      }

      // Validate and normalize groupId
      String effectiveGroupId = event.groupId;

      // Create location if needed
      String? locationId;
      if (event.location != null) {
        try {
          final locationData = await _dataSource.createLocation(
            displayName: event.location!.displayName,
            formattedAddress: event.location!.formattedAddress,
            latitude: event.location!.latitude,
            longitude: event.location!.longitude,
            createdBy: userId,
          );
          locationId = locationData['id'] as String;
        } catch (e) {
          if (e.toString().contains('row-level security policy')) {
            locationId = null;
          } else {
            rethrow;
          }
        }
      }

      // Convert domain entity to DTO with location ID

      Map<String, dynamic> response;
      try {
        response = await _dataSource.createEvent(
          name: event.name,
          emoji: event.emoji,
          groupId: effectiveGroupId,
          startDateTime: event.startDateTime,
          endDateTime: event.endDateTime,
          locationId: locationId,
          status: event.status.toString().split('.').last,
          createdBy: userId,
        );
      } catch (e) {
        rethrow;
      }

      final eventId = response['id'] as String;

      // ✅ TRIGGER HANDLING:
      // The Supabase trigger 'on_event_created_add_par...' automatically adds
      // all group members as participants with rsvp='pending'.
      // We need to UPDATE the creator's RSVP from 'pending' to 'yes'.

      try {
        // Wait a tiny bit for trigger to complete (triggers run async)
        await Future.delayed(const Duration(milliseconds: 100));

        await _client
            .from('event_participants')
            .update({
              'rsvp': 'yes',
              'confirmed_at': DateTime.now().toIso8601String(),
            })
            .eq('pevent_id', eventId)
            .eq('user_id', userId)
            .select();
      } catch (e) {
        // Don't fail event creation if RSVP update fails
      }

      // If event has initial date/time, create it as a suggestion
      if (event.startDateTime != null) {
        try {
          final suggestionResponse = await _client
              .from('event_date_options')
              .insert({
                'event_id': eventId,
                'created_by': userId,
                'starts_at': event.startDateTime!.toIso8601String(),
                'ends_at': event.endDateTime?.toIso8601String(),
              })
              .select('id')
              .single();

          final optionId = suggestionResponse['id'] as String;

          // Auto-vote for the event creator on the initial date suggestion
          try {
            await _client.from('event_date_votes').insert({
              'option_id': optionId,
              'user_id': userId,
              'event_id': eventId,
            });
          } catch (e) {
            // Don't fail event creation if vote fails
          }
        } catch (e) {
          // Don't fail event creation if suggestion fails
        }
      }

      // If event has initial location, create it as a suggestion
      if (event.location != null && locationId != null) {
        try {
          await _client.from('location_suggestions').insert({
            'event_id': eventId,
            'user_id': userId,
            'location_name': event.location!.displayName,
            'address': event.location!.formattedAddress,
            'latitude': event.location!.latitude,
            'longitude': event.location!.longitude,
          });
        } catch (e) {
          // Don't fail event creation if suggestion fails
        }
      }

      // Send "Event Created" notification to all group members except creator
      try {
        // Get creator name and group name
        final userResponse = await _client
            .from('users')
            .select('name')
            .eq('id', userId)
            .single();
        
        final groupResponse = await _client
            .from('groups')
            .select('name')
            .eq('id', effectiveGroupId)
            .single();
        
        final creatorName = userResponse['name'] as String;
        final groupName = groupResponse['name'] as String;
        
        // Get all group members except the creator
        final membersResponse = await _client
            .from('group_members')
            .select('user_id')
            .eq('group_id', effectiveGroupId)
            .neq('user_id', userId);
        
        // Send notification to each member
        for (final member in membersResponse) {
          final memberId = member['user_id'] as String;
          await _notificationService.sendEventCreated(
            recipientUserId: memberId,
            creatorName: creatorName,
            eventName: event.name,
            groupName: groupName,
            eventId: eventId,
            groupId: effectiveGroupId,
            eventEmoji: event.emoji,
          );
        }
      } catch (e) {
        // Don't fail event creation if notification fails
      }

      return EventModel.fromJson(response).toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Event?> getEventById(String id) async {
    final response = await _dataSource.getEventById(id);
    if (response == null) return null;
    // Fetch location if present
    String? locationId = response['location_id'] as String?;
    EventLocation? location;
    if (locationId != null) {
      final loc = await _dataSource.getLocationById(locationId);
      if (loc != null) {
        location = LocationModel.fromJson(loc).toEntity();
      }
    }
    return EventModel.fromJson(response).toEntity(location: location);
  }

  @override
  Future<Event> updateEvent(Event event) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      // CRITICAL: Create location first if it's a new location (no ID yet)
      String? locationId;
      if (event.location != null) {
        // Check if location already exists in DB (has valid UUID)
        final existingId = event.location!.id;
        final uuidRegex = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false);

        if (uuidRegex.hasMatch(existingId)) {
          // Location already exists, just use its ID
          locationId = existingId;
        } else {
          // New location or temp-id - create it first
          final locationData = await _dataSource.createLocation(
            displayName: event.location!.displayName,
            formattedAddress: event.location!.formattedAddress,
            latitude: event.location!.latitude,
            longitude: event.location!.longitude,
            createdBy: userId,
          );
          locationId = locationData['id'] as String;
        }
      }

      // Now update the event with the location ID
      final response = await _dataSource.updateEvent(
        id: event.id,
        name: event.name,
        emoji: event.emoji,
        groupId: event.groupId,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        locationId: locationId,
        status: event.status.toString().split('.').last,
      );

      // CRITICAL: Sync the initial date suggestion created by host/admin
      // When an event is created with a date, we auto-create a suggestion
      // When editing, we must also UPDATE that suggestion to avoid showing it as "alternate"
      try {
        // Find the initial suggestion created by the event creator (host)
        final initialSuggestions = await _client
            .from('event_date_options')
            .select('id')
            .eq('event_id', event.id)
            .eq('created_by', userId)
            .order('created_at', ascending: true)
            .limit(1);

        if (initialSuggestions.isNotEmpty && event.startDateTime != null) {
          // Update the initial suggestion to match the new event date
          final suggestionId = initialSuggestions[0]['id'];
          await _client.from('event_date_options').update({
            'starts_at': event.startDateTime!.toIso8601String(),
            'ends_at': event.endDateTime?.toIso8601String(),
          }).eq('id', suggestionId);
        } else if (initialSuggestions.isNotEmpty &&
            event.startDateTime == null) {
          // Event changed to "Decide Later" - delete the suggestion
          final suggestionId = initialSuggestions[0]['id'];
          await _client
              .from('event_date_options')
              .delete()
              .eq('id', suggestionId);
        }
      } catch (e) {
        // Don't fail the update if suggestion sync fails
      }

      // CRITICAL: Sync the initial location suggestion created by host/admin
      try {
        // Find the initial location suggestion created by the event creator
        final initialLocationSuggestions = await _client
            .from('location_suggestions')
            .select('id')
            .eq('event_id', event.id)
            .eq('user_id', userId)
            .order('created_at', ascending: true)
            .limit(1);

        if (initialLocationSuggestions.isNotEmpty &&
            event.location != null &&
            locationId != null) {
          // Update the initial suggestion to match the new event location
          final suggestionId = initialLocationSuggestions[0]['id'];
          await _client.from('location_suggestions').update({
            'location_name': event.location!.displayName,
            'address': event.location!.formattedAddress,
            'latitude': event.location!.latitude,
            'longitude': event.location!.longitude,
          }).eq('id', suggestionId);
        } else if (initialLocationSuggestions.isNotEmpty &&
            event.location == null) {
          // Event changed to "Decide Later" for location - delete the suggestion
          final suggestionId = initialLocationSuggestions[0]['id'];
          await _client
              .from('location_suggestions')
              .delete()
              .eq('id', suggestionId);
        }
      } catch (e) {
        // Don't fail the update if location suggestion sync fails
      }

      // Fetch location if present in updated event
      String? finalLocationId = response['location_id'] as String?;
      EventLocation? location;
      if (finalLocationId != null) {
        final loc = await _dataSource.getLocationById(finalLocationId);
        if (loc != null) {
          location = LocationModel.fromJson(loc).toEntity();
        }
      }

      final updatedEvent =
          EventModel.fromJson(response).toEntity(location: location);

      // CRITICAL: Send notifications to participants when event is extended
      // Check if event duration was increased (end time pushed forward)
      try {
        // Get the previous event data to compare end times
        final previousEvent = await getEventById(event.id);

        if (previousEvent != null &&
            previousEvent.endDateTime != null &&
            event.endDateTime != null &&
            event.endDateTime!.isAfter(previousEvent.endDateTime!)) {
          // Calculate how many hours the event was extended
          final extension =
              event.endDateTime!.difference(previousEvent.endDateTime!);
          final additionalHours = (extension.inMinutes / 60).ceil();

          // Get all participants of this event (except the current user)
          final participants = await _client
              .from('event_participants')
              .select('user_id')
              .eq('pevent_id', event.id)
              .neq('user_id', userId);

          // Send notification to each participant
          for (final participant in participants) {
            final participantId = participant['user_id'] as String;

            await _notificationService.sendEventExtended(
              recipientUserId: participantId,
              eventName: event.name,
              eventId: event.id,
              additionalHours: additionalHours,
              eventEmoji: event.emoji,
            );
          }
        }
      } catch (e) {
        // Don't fail the update if notification fails
      }

      return updatedEvent;
    } on Exception catch (e) {
      // Re-throw with better context
      throw Exception('Failed to update event: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _dataSource.deleteEvent(id);
  }

  @override
  Future<List<Event>> getEventsForGroup(String groupId) async {
    final response = await _dataSource.getEventsForGroup(groupId);
    List<Event> events = [];
    for (final row in response) {
      // Fetch location if present
      String? locationId = row['location_id'] as String?;
      EventLocation? location;
      if (locationId != null) {
        final loc = await _dataSource.getLocationById(locationId);
        if (loc != null) {
          location = LocationModel.fromJson(loc).toEntity();
        }
      }
      events.add(EventModel.fromJson(row).toEntity(location: location));
    }
    return events;
  }

  @override
  Future<List<EventLocation>> searchLocations(String query) async {
    final response = await _dataSource.searchLocations(query);
    return response
        .map((row) => LocationModel.fromJson(row).toEntity())
        .toList();
  }

  @override
  Future<EventLocation?> getCurrentLocation() async {
    // Not implemented: should use platform channel or service
    // Return null or throw UnimplementedError
    return null;
  }

  @override
  Future<List<EventHistory>> getUserEventHistory({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final response = await _dataSource.getUserEventHistory(
        userId: userId,
        limit: limit,
      );

      final entities = response.map((json) {
        return EventHistoryModel.fromJson(json).toEntity();
      }).toList();

      return entities;
    } catch (e) {
      throw Exception('Repository: Failed to get user event history - $e');
    }
  }
}
