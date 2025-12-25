import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle event status transitions
///
/// Event Status Flow:
/// pending → confirmed → living → recap → ended
///
/// Transitions:
/// - confirmed → living: when event start_datetime is reached
/// - living → recap: when event end_datetime is reached
/// - recap → ended: 24 hours after event end_datetime
///
/// This service should ideally be replaced by:
/// 1. Supabase Edge Function (cron job every minute)
/// 2. Database trigger on events table
/// 3. Backend service with scheduled tasks
class EventStatusService {
  final SupabaseClient _client;

  EventStatusService(this._client);

  /// Update event statuses based on current time
  ///
  /// This method checks all confirmed and living events and updates their
  /// status based on start/end times.
  ///
  /// Returns: number of events updated
  Future<int> updateEventStatuses() async {
    try {
      final now = DateTime.now().toUtc();
      int updatedCount = 0;

      print('[EventStatusService] ===== updateEventStatuses called =====');
      print('[EventStatusService] Current UTC time: $now');

      // 1. Find confirmed events that should be living (start_datetime has passed)
      print(
          '[EventStatusService] Checking confirmed events to transition to living...');
      print('[EventStatusService] Current time: $now');

      final confirmedToLiving = await _client
          .from('events')
          .select('id, name, start_datetime, status')
          .eq('status', 'confirmed')
          .lte('start_datetime', now.toIso8601String());

      print(
          '[EventStatusService] Found ${confirmedToLiving.length} confirmed events that should be living');

      if (confirmedToLiving.isNotEmpty) {
        for (final event in confirmedToLiving) {
          print(
              '[EventStatusService] Transitioning event ${event['name']} (${event['id']}) from confirmed to living');
          print(
              '[EventStatusService] Event start_datetime: ${event['start_datetime']}');

          await _client
              .from('events')
              .update({'status': 'living'}).eq('id', event['id']);
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
          updatedCount++;
        }
      } else {}

      if (updatedCount > 0) {
      } else {}

      return updatedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Update status for a specific event
  /// Useful when you know an event needs updating
  Future<bool> updateEventStatus(String eventId) async {
    try {
      print(
          '[EventStatusService] updateEventStatus called for event: $eventId');

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

      print('[EventStatusService] Event: ${event['name']}');
      print('[EventStatusService] Current status: $currentStatus');
      print('[EventStatusService] Start time: $startTime');
      print('[EventStatusService] End time: $endTime');
      print('[EventStatusService] Current time: $now');
      print('[EventStatusService] Is after start? ${now.isAfter(startTime)}');

      String? newStatus;

      // Only transition events that are already confirmed or beyond
      // Pending events should remain pending even if time has passed
      if (currentStatus == 'pending') {
        // Pending events never auto-transition
        print(
            '[EventStatusService] Event is PENDING - no auto-transition allowed');
        print(
            '[EventStatusService] Event should remain pending (isExpired will handle UI)');
        return false;
      }

      // Determine correct status based on times (only for confirmed+ events)
      if (now.isAfter(recapDeadline)) {
        newStatus = 'ended';
      } else if (now.isAfter(endTime)) {
        newStatus = 'recap';
      } else if (now.isAfter(startTime)) {
        newStatus = 'living';
      } else {
        newStatus = 'confirmed';
      }

      if (newStatus != currentStatus) {
        print(
            '[EventStatusService] Updating status from $currentStatus to $newStatus');
        await _client
            .from('events')
            .update({'status': newStatus}).eq('id', eventId);
        print('[EventStatusService] Status updated successfully');
        return true;
      } else {
        print('[EventStatusService] Status unchanged ($currentStatus)');
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
