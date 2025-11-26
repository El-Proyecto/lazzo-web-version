import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_data_source.dart';
import '../models/event_original_model.dart';
import '../models/location_model.dart';
import '../../../../env.dart';

/// Implementation of EventRepository using Supabase

class EventRepositoryImpl implements EventRepository {
	final EventDataSource _dataSource;
	final SupabaseClient _client;

	EventRepositoryImpl(SupabaseClient client)
			: _dataSource = EventDataSource(client),
				_client = client;

	/// Get current authenticated user ID
	String? get _currentUserId => _client.auth.currentUser?.id;

	@override
	Future<Event> createEvent(Event event) async {
		try {
			final userId = _currentUserId;
			final user = _client.auth.currentUser;
			
			print('🔐 DEBUG: Current user: $user');
			print('🔐 DEBUG: User ID: $userId');
			print('🔐 DEBUG: User null? ${user == null}');
			print('🔐 DEBUG: Session: ${_client.auth.currentSession}');
			
			if (userId == null || userId.isEmpty) {
				throw Exception('User must be authenticated to create events');
			}
			
			// Validate and normalize groupId
			String effectiveGroupId = event.groupId;
			
			// Check if groupId is a valid UUID format
			final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
			if (!uuidRegex.hasMatch(event.groupId)) {
				print('⚠️ DEBUG: Invalid groupId format: ${event.groupId}, using development fallback');
				effectiveGroupId = Env.devDefaultGroupId;
				
				// Validate the fallback too
				if (!uuidRegex.hasMatch(effectiveGroupId) || effectiveGroupId == 'REPLACE_WITH_VALID_GROUP_UUID') {
					throw Exception('Invalid development groupId. Please set Env.devDefaultGroupId to a valid UUID from your groups table.');
				}
			}
			
			print('� DEBUG: Using groupId: $effectiveGroupId');
			
			// Create location if needed
			String? locationId;
			if (event.location != null) {
				print('📍 DEBUG: Creating location...');
				try {
					final locationData = await _dataSource.createLocation(
						displayName: event.location!.displayName,
						formattedAddress: event.location!.formattedAddress,
						latitude: event.location!.latitude,
						longitude: event.location!.longitude,
						createdBy: userId,
					);
					locationId = locationData['id'] as String;
					print('📍 DEBUG: Location created with ID: $locationId');
				} catch (e) {
					if (e.toString().contains('row-level security policy')) {
						print('❌ RLS ERROR: Cannot create location. Check that locations table has created_by column and INSERT policy allows created_by = auth.uid()');
						print('❌ Continuing without location for now...');
						locationId = null;
					} else {
						rethrow;
					}
				}
			}
			
			// Convert domain entity to DTO with location ID
			print('📝 DEBUG: Creating event with data:');
			print('📝 DEBUG: - name: ${event.name}');
			print('📝 DEBUG: - groupId: $effectiveGroupId');
			print('📝 DEBUG: - createdBy: $userId');
			print('📝 DEBUG: - locationId: $locationId');
			
			final response = await _dataSource.createEvent(
				name: event.name,
				emoji: event.emoji,
				groupId: effectiveGroupId,
				startDateTime: event.startDateTime,
				endDateTime: event.endDateTime,
				locationId: locationId,
				status: event.status.toString().split('.').last,
				createdBy: userId,
			);
			
			print('📝 SUCCESS: Event created with ID: ${response['id']}');
			
			final eventId = response['id'] as String;
			
		// Create initial RSVP for event creator (automatically "yes")
		try {
			await _client.from('event_participants').insert({
				'pevent_id': eventId,
				'user_id': userId,
				'rsvp': 'yes', // rsvp_status enum: pending, yes, no, maybe
				'confirmed_at': DateTime.now().toIso8601String(),
			});
		} catch (e) {
			// Don't fail event creation if RSVP fails
		}			// If event has initial date/time, create it as a suggestion
			if (event.startDateTime != null) {
				try {
					final suggestionResponse = await _client.from('event_date_options').insert({
						'event_id': eventId,
						'created_by': userId,
						'starts_at': event.startDateTime!.toIso8601String(),
						'ends_at': event.endDateTime?.toIso8601String(),
					}).select('id').single();
					
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
				final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
				
				if (uuidRegex.hasMatch(existingId)) {
					// Location already exists, just use its ID
					locationId = existingId;
					print('📍 Using existing location: $locationId');
				} else {
					// New location - create it first
					print('📍 Creating new location for update...');
					try {
						final locationData = await _dataSource.createLocation(
							displayName: event.location!.displayName,
							formattedAddress: event.location!.formattedAddress,
							latitude: event.location!.latitude,
							longitude: event.location!.longitude,
							createdBy: userId,
						);
						locationId = locationData['id'] as String;
						print('📍 Location created with ID: $locationId');
					} catch (e) {
						print('❌ Failed to create location: $e');
						// Don't fail the entire update, just log it
						locationId = null;
					}
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
					print('✅ Updated initial date suggestion to match edited event');
				} else if (initialSuggestions.isNotEmpty && event.startDateTime == null) {
					// Event changed to "Decide Later" - delete the suggestion
					final suggestionId = initialSuggestions[0]['id'];
					await _client.from('event_date_options').delete().eq('id', suggestionId);
					print('✅ Deleted date suggestion (event changed to Decide Later)');
				}
			} catch (e) {
				// Don't fail the update if suggestion sync fails
				print('⚠️ Failed to sync date suggestion: $e');
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
				
				if (initialLocationSuggestions.isNotEmpty && event.location != null && locationId != null) {
					// Update the initial suggestion to match the new event location
					final suggestionId = initialLocationSuggestions[0]['id'];
					await _client.from('location_suggestions').update({
						'location_name': event.location!.displayName,
						'address': event.location!.formattedAddress,
						'latitude': event.location!.latitude,
						'longitude': event.location!.longitude,
					}).eq('id', suggestionId);
					print('✅ Updated initial location suggestion to match edited event');
				} else if (initialLocationSuggestions.isNotEmpty && event.location == null) {
					// Event changed to "Decide Later" for location - delete the suggestion
					final suggestionId = initialLocationSuggestions[0]['id'];
					await _client.from('location_suggestions').delete().eq('id', suggestionId);
					print('✅ Deleted location suggestion (event changed to Decide Later)');
				}
			} catch (e) {
				// Don't fail the update if location suggestion sync fails
				print('⚠️ Failed to sync location suggestion: $e');
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
			
			return EventModel.fromJson(response).toEntity(location: location);
		} on Exception catch (e) {
			// Re-throw with better context
			print('❌ Update event error: $e');
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
		return response.map((row) => LocationModel.fromJson(row).toEntity()).toList();
	}

	@override
	Future<EventLocation?> getCurrentLocation() async {
		// Not implemented: should use platform channel or service
		// Return null or throw UnimplementedError
		return null;
	}
}

