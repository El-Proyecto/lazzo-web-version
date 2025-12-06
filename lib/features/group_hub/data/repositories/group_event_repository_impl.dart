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
            
      final jsonList = await _dataSource.getGroupEvents(groupId);
      
            
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
    } catch (e) {
                  return [];
    }
  }

  @override
  Future<GroupEventEntity?> getEventById(String eventId) async {
    try {
            
      final json = await _dataSource.getEventById(eventId);
      if (json == null) {
                return null;
      }
      
      // Fetch RSVPs separately and merge
      final rsvps = await _dataSource.getEventRsvps(eventId);
      
            
      return GroupEventModel.fromJson(json, rsvps: rsvps);
    } catch (e) {
                  return null;
    }
  }
}
