import '../../domain/entities/group_event_entity.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../data_sources/group_event_data_source.dart';

/// Supabase implementation of GroupEventRepository
/// 
/// P2 Implementation Requirements:
/// - Use GroupEventDataSource to fetch data from Supabase
/// - Convert raw JSON to entities using GroupEventModel
/// - Handle errors and return empty lists/null gracefully
/// - Add logging for debugging
class GroupEventRepositoryImpl implements GroupEventRepository {
  // ignore: unused_field
  final GroupEventDataSource _dataSource;

  GroupEventRepositoryImpl(this._dataSource);

  @override
  Future<List<GroupEventEntity>> getGroupEvents(String groupId) async {
    // P2 TODO: Implement repository method
    // 
    // Implementation steps:
    // 1. Call _dataSource.getGroupEvents(groupId)
    // 2. Convert each JSON map to GroupEventEntity using GroupEventModel.fromJson()
    // 3. Handle errors (catch exceptions, log, return empty list)
    // 4. Return list of entities
    //
    // Example implementation:
    // try {
    //   final jsonList = await _dataSource.getGroupEvents(groupId);
    //   return jsonList
    //       .map((json) => GroupEventModel.fromJson(json))
    //       .toList();
    // } catch (e, stackTrace) {
    //   // Log error
    //   print('Error fetching group events: $e');
    //   print(stackTrace);
    //   return [];
    // }

    throw UnimplementedError('P2: Implement getGroupEvents repository method');
  }

  @override
  Future<GroupEventEntity?> getEventById(String eventId) async {
    // P2 TODO: Implement repository method
    // 
    // Implementation steps:
    // 1. Call _dataSource.getEventById(eventId)
    // 2. If null, return null
    // 3. Convert JSON to GroupEventEntity using GroupEventModel.fromJson()
    // 4. Handle errors (catch exceptions, log, return null)
    // 5. Return entity or null
    //
    // Example implementation:
    // try {
    //   final json = await _dataSource.getEventById(eventId);
    //   if (json == null) return null;
    //   
    //   // Fetch RSVPs separately and merge
    //   final rsvps = await _dataSource.getEventRsvps(eventId);
    //   json['rsvps'] = rsvps;
    //   
    //   return GroupEventModel.fromJson(json);
    // } catch (e, stackTrace) {
    //   print('Error fetching event by ID: $e');
    //   print(stackTrace);
    //   return null;
    // }

    throw UnimplementedError('P2: Implement getEventById repository method');
  }
}
