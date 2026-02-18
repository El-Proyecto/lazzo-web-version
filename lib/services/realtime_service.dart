import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Realtime service for live updates (e.g., web RSVP → app sync).
///
/// Subscribes to Postgres changes on tables like `event_participants`
/// and emits change events so Riverpod providers can invalidate/refresh.
class RealtimeService {
  final SupabaseClient _client;
  RealtimeChannel? _rsvpChannel;
  RealtimeChannel? _eventsChannel;

  final _rsvpChanges = StreamController<RealtimeChangeEvent>.broadcast();
  final _eventChanges = StreamController<RealtimeChangeEvent>.broadcast();

  /// Stream of RSVP changes (INSERT / UPDATE / DELETE on event_participants)
  Stream<RealtimeChangeEvent> get rsvpChanges => _rsvpChanges.stream;

  /// Stream of event changes (UPDATE on events — e.g. status, cover_photo)
  Stream<RealtimeChangeEvent> get eventChanges => _eventChanges.stream;

  RealtimeService(this._client);

  /// Start listening. Call once after auth is confirmed.
  void subscribe() {
    _subscribeRsvps();
    _subscribeEvents();
  }

  void _subscribeRsvps() {
    _rsvpChannel = _client
        .channel('realtime:event_participants')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_participants',
          callback: (payload) {
            _rsvpChanges.add(RealtimeChangeEvent(
              table: 'event_participants',
              eventType: payload.eventType.name,
              newRecord: payload.newRecord,
              oldRecord: payload.oldRecord,
            ));
          },
        )
        .subscribe();
  }

  void _subscribeEvents() {
    _eventsChannel = _client
        .channel('realtime:events')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            _eventChanges.add(RealtimeChangeEvent(
              table: 'events',
              eventType: payload.eventType.name,
              newRecord: payload.newRecord,
              oldRecord: payload.oldRecord,
            ));
          },
        )
        .subscribe();
  }

  /// Stop listening and release resources.
  Future<void> dispose() async {
    if (_rsvpChannel != null) {
      await _client.removeChannel(_rsvpChannel!);
    }
    if (_eventsChannel != null) {
      await _client.removeChannel(_eventsChannel!);
    }
    await _rsvpChanges.close();
    await _eventChanges.close();
  }
}

/// Lightweight DTO for a realtime change.
class RealtimeChangeEvent {
  final String table;
  final String eventType; // INSERT, UPDATE, DELETE
  final Map<String, dynamic> newRecord;
  final Map<String, dynamic> oldRecord;

  const RealtimeChangeEvent({
    required this.table,
    required this.eventType,
    required this.newRecord,
    required this.oldRecord,
  });

  /// The event ID affected (works for both event_participants.pevent_id and events.id)
  String? get eventId {
    return (newRecord['pevent_id'] ?? newRecord['id'] ?? oldRecord['pevent_id'] ?? oldRecord['id']) as String?;
  }
}

// ─── Riverpod providers ─────────────────────────────────────────────────

/// Singleton provider for the realtime service.
/// Overridden in main.dart with the real SupabaseClient.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(Supabase.instance.client);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider that watches RSVP changes.
/// Widgets / other providers can `ref.watch` this to react to live RSVP updates.
final rsvpRealtimeProvider = StreamProvider<RealtimeChangeEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.rsvpChanges;
});

/// Stream provider that watches event record changes.
final eventRealtimeProvider = StreamProvider<RealtimeChangeEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.eventChanges;
});
