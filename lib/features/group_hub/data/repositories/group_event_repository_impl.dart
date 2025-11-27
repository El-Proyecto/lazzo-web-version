import '../../domain/entities/group_event_entity.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../data_sources/group_event_data_source.dart';
import '../models/group_event_model.dart';

/// Supabase implementation of GroupEventRepository
class GroupEventRepositoryImpl implements GroupEventRepository {
  final GroupEventDataSource _dataSource;

  GroupEventRepositoryImpl(this._dataSource);

  @override
  Future<List<GroupEventEntity>> getGroupEvents(String groupId) async {
    try {
      print('📋 Fetching group events for group: $groupId');
      
      final jsonList = await _dataSource.getGroupEvents(groupId);
      
      print('✅ Fetched ${jsonList.length} events from Supabase');
      
      // Fetch RSVPs for each event to populate allVotes
      final events = <GroupEventEntity>[];
      for (final json in jsonList) {
        final eventId = json['event_id'] as String?;
        if (eventId != null) {
          final rsvps = await _dataSource.getEventRsvps(eventId);
          events.add(GroupEventModel.fromJson(json, rsvps: rsvps));
        } else {
          events.add(GroupEventModel.fromJson(json));
        }
      }
      
      return events;
    } catch (e, stackTrace) {
      print('❌ Error fetching group events: $e');
      print(stackTrace);
      return [];
    }
  }

  @override
  Future<GroupEventEntity?> getEventById(String eventId) async {
    try {
      print('📋 Fetching event by ID: $eventId');
      
      final json = await _dataSource.getEventById(eventId);
      if (json == null) {
        print('⚠️ Event not found: $eventId');
        return null;
      }
      
      // Fetch RSVPs separately and merge
      final rsvps = await _dataSource.getEventRsvps(eventId);
      
      print('✅ Fetched event with ${rsvps.length} RSVPs');
      
      return GroupEventModel.fromJson(json, rsvps: rsvps);
    } catch (e, stackTrace) {
      print('❌ Error fetching event by ID: $e');
      print(stackTrace);
      return null;
    }
  }
}
