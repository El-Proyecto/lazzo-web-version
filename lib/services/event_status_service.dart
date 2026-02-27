import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_service.dart';

/// Service to handle event status transitions
///
/// Event Status Flow:
/// pending → confirmed → living → recap → ended
/// pending → expired (if start_datetime passes without confirmation)
///
/// Transitions:
/// - pending → expired: when start_datetime passes without confirmation
/// - confirmed → living: when event start_datetime is reached
/// - living → recap: when event end_datetime is reached
/// - recap → ended: 24 hours after event end_datetime
///
/// This service runs client-side for immediate feedback.
/// A server-side Edge Function (transition-event-phases) also handles
/// these transitions via cron for guaranteed execution.
class EventStatusService {
  final SupabaseClient _client;

  EventStatusService(this._client);

  /// Track event_phase_changed for automatic transitions
  static void _trackPhaseChange(String eventId, String from, String to) {
    AnalyticsService.track('event_phase_changed', properties: {
      'event_id': eventId,
      'from_phase': from,
      'to_phase': to,
      'trigger': 'auto',
      'platform': 'ios',
    });
  }

  /// Update event statuses based on current time
  ///
  /// This method checks all events and updates their
  /// status based on start/end times.
  ///
  /// Returns: number of events updated
  Future<int> updateEventStatuses() async {
    try {
      final now = DateTime.now().toUtc();
      int updatedCount = 0;

      // 0. Find pending events that should be expired (start_datetime has passed)
      final pendingToExpired = await _client
          .from('events')
          .select('id, name, start_datetime, status')
          .eq('status', 'pending')
          .not('start_datetime', 'is', null)
          .lte('start_datetime', now.toIso8601String());

      if (pendingToExpired.isNotEmpty) {
        for (final event in pendingToExpired) {
          await _client
              .from('events')
              .update({'status': 'expired'}).eq('id', event['id']);
          _trackPhaseChange(event['id'] as String, 'pending', 'expired');
          updatedCount++;
        }
      }

      // 1. Find confirmed events that should be living (start_datetime has passed)
      final confirmedToLiving = await _client
          .from('events')
          .select('id, name, start_datetime, status')
          .eq('status', 'confirmed')
          .lte('start_datetime', now.toIso8601String());

      if (confirmedToLiving.isNotEmpty) {
        for (final event in confirmedToLiving) {
          await _client
              .from('events')
              .update({'status': 'living'}).eq('id', event['id']);
          _trackPhaseChange(event['id'] as String, 'confirmed', 'living');
          updatedCount++;
        }
      }

      // 2. Find living events that should be recap (end_datetime has passed)
      final livingToRecap = await _client
          .from('events')
          .select('id, name, end_datetime')
          .eq('status', 'living')
          .lte('end_datetime', now.toIso8601String());

      if (livingToRecap.isNotEmpty) {
        for (final event in livingToRecap) {
          await _client
              .from('events')
              .update({'status': 'recap'}).eq('id', event['id']);
          _trackPhaseChange(event['id'] as String, 'living', 'recap');
          updatedCount++;
        }
      }

      // 3. Find recap events that should be ended (24h after end_datetime)
      final recapDeadline = now.subtract(const Duration(hours: 24));

      final recapToEnded = await _client
          .from('events')
          .select('id, name, end_datetime')
          .eq('status', 'recap')
          .lte('end_datetime', recapDeadline.toIso8601String());

      if (recapToEnded.isNotEmpty) {
        for (final event in recapToEnded) {
          await _client
              .from('events')
              .update({'status': 'ended'}).eq('id', event['id']);
          _trackPhaseChange(event['id'] as String, 'recap', 'ended');
          updatedCount++;
        }
      }

      return updatedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Update status for a specific event
  /// Useful when you know an event needs updating
  Future<bool> updateEventStatus(String eventId) async {
    try {
      final event = await _client
          .from('events')
          .select('id, name, status, start_datetime, end_datetime')
          .eq('id', eventId)
          .single();

      final now = DateTime.now().toUtc();
      final startTime = DateTime.parse(event['start_datetime'] as String);
      final endTime = DateTime.parse(event['end_datetime'] as String);
      final recapDeadline = endTime.add(const Duration(hours: 24));
      final currentStatus = event['status'] as String;

      String? newStatus;

      // Pending events with past start_datetime → expired
      if (currentStatus == 'pending') {
        if (now.isAfter(startTime)) {
          newStatus = 'expired';
        } else {
          return false;
        }
      } else if (now.isAfter(recapDeadline)) {
        newStatus = 'ended';
      } else if (now.isAfter(endTime)) {
        newStatus = 'recap';
      } else if (now.isAfter(startTime)) {
        newStatus = 'living';
      } else {
        newStatus = 'confirmed';
      }

      if (newStatus != currentStatus) {
        await _client
            .from('events')
            .update({'status': newStatus}).eq('id', eventId);
        _trackPhaseChange(eventId, currentStatus, newStatus);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get events that need status updates (for debugging)
  Future<Map<String, List<Map<String, dynamic>>>>
      getEventsNeedingUpdate() async {
    try {
      final now = DateTime.now().toUtc();
      final recapDeadline = now.subtract(const Duration(hours: 24));

      final confirmedToLiving = await _client
          .from('events')
          .select('id, name, start_datetime, end_datetime, status')
          .eq('status', 'confirmed')
          .lte('start_datetime', now.toIso8601String());

      final livingToRecap = await _client
          .from('events')
          .select('id, name, start_datetime, end_datetime, status')
          .eq('status', 'living')
          .lte('end_datetime', now.toIso8601String());

      final recapToEnded = await _client
          .from('events')
          .select('id, name, start_datetime, end_datetime, status')
          .eq('status', 'recap')
          .lte('end_datetime', recapDeadline.toIso8601String());

      return {
        'confirmed_to_living':
            List<Map<String, dynamic>>.from(confirmedToLiving),
        'living_to_recap': List<Map<String, dynamic>>.from(livingToRecap),
        'recap_to_ended': List<Map<String, dynamic>>.from(recapToEnded),
      };
    } catch (e) {
      return {
        'confirmed_to_living': [],
        'living_to_recap': [],
        'recap_to_ended': [],
      };
    }
  }
}
