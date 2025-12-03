import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle event status transitions
/// 
/// Event Status Flow:
/// pending → confirmed → living → recap
/// 
/// Transitions:
/// - confirmed → living: when event start_datetime is reached
/// - living → recap: when event end_datetime is reached
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
    print('\n🔄 [EVENT STATUS SERVICE] Checking for status transitions...');
    
    try {
      final now = DateTime.now().toUtc();
      int updatedCount = 0;

      // 1. Find confirmed events that should be living (start_datetime has passed)
      print('🔍 [STATUS] Checking confirmed events that should be living...');
      final confirmedToLiving = await _client
          .from('events')
          .select('id, name, start_datetime')
          .eq('status', 'confirmed')
          .lte('start_datetime', now.toIso8601String());

      if (confirmedToLiving.isNotEmpty) {
        print('✅ [STATUS] Found ${confirmedToLiving.length} confirmed events that should be living');
        
        for (final event in confirmedToLiving) {
          print('   🔄 Transitioning: ${event['name']} (${event['id']}) → living');
          await _client
              .from('events')
              .update({'status': 'living'})
              .eq('id', event['id']);
          updatedCount++;
        }
      }

      // 2. Find living events that should be recap (end_datetime has passed)
      print('🔍 [STATUS] Checking living events that should be recap...');
      final livingToRecap = await _client
          .from('events')
          .select('id, name, end_datetime')
          .eq('status', 'living')
          .lte('end_datetime', now.toIso8601String());

      if (livingToRecap.isNotEmpty) {
        print('✅ [STATUS] Found ${livingToRecap.length} living events that should be recap');
        
        for (final event in livingToRecap) {
          print('   🔄 Transitioning: ${event['name']} (${event['id']}) → recap');
          await _client
              .from('events')
              .update({'status': 'recap'})
              .eq('id', event['id']);
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        print('✅ [EVENT STATUS SERVICE] Updated $updatedCount events');
      } else {
        print('ℹ️ [EVENT STATUS SERVICE] No events need status updates');
      }

      return updatedCount;
    } catch (e, stackTrace) {
      print('❌ [EVENT STATUS SERVICE] Error updating statuses: $e');
      print('   Stack: $stackTrace');
      return 0;
    }
  }

  /// Update status for a specific event
  /// Useful when you know an event needs updating
  Future<bool> updateEventStatus(String eventId) async {
    try {
      print('\n🔄 [EVENT STATUS SERVICE] Updating event: $eventId');
      
      final event = await _client
          .from('events')
          .select('id, name, status, start_datetime, end_datetime')
          .eq('id', eventId)
          .single();

      final now = DateTime.now().toUtc();
      final startTime = DateTime.parse(event['start_datetime'] as String);
      final endTime = DateTime.parse(event['end_datetime'] as String);
      final currentStatus = event['status'] as String;

      String? newStatus;

      // Determine correct status based on times
      if (now.isAfter(endTime)) {
        newStatus = 'recap';
      } else if (now.isAfter(startTime)) {
        newStatus = 'living';
      } else {
        newStatus = 'confirmed';
      }

      if (newStatus != currentStatus) {
        print('✅ [STATUS] Transitioning: ${event['name']} → $newStatus');
        await _client
            .from('events')
            .update({'status': newStatus})
            .eq('id', eventId);
        return true;
      } else {
        print('ℹ️ [STATUS] Event already has correct status: $currentStatus');
        return false;
      }
    } catch (e) {
      print('❌ [EVENT STATUS SERVICE] Error updating event $eventId: $e');
      return false;
    }
  }

  /// Get events that need status updates (for debugging)
  Future<Map<String, List<Map<String, dynamic>>>> getEventsNeedingUpdate() async {
    try {
      final now = DateTime.now().toUtc();

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

      return {
        'confirmed_to_living': List<Map<String, dynamic>>.from(confirmedToLiving),
        'living_to_recap': List<Map<String, dynamic>>.from(livingToRecap),
      };
    } catch (e) {
      print('❌ [EVENT STATUS SERVICE] Error checking events: $e');
      return {
        'confirmed_to_living': [],
        'living_to_recap': [],
      };
    }
  }
}
