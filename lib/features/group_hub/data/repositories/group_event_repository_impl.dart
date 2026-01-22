import '../../domain/entities/group_event_entity.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../data_sources/group_event_data_source.dart';
import '../models/group_event_model.dart';

/// Supabase implementation of GroupEventRepository
class GroupEventRepositoryImpl implements GroupEventRepository {
  final GroupEventDataSource _dataSource;

  GroupEventRepositoryImpl(this._dataSource);

  @override
  Future<List<GroupEventEntity>> getGroupEvents(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  }) async {
    try {
      final jsonList = await _dataSource.getGroupEvents(
        groupId,
        pageSize: pageSize,
        offset: offset,
      );

      // ✅ OPTIMIZATION: Extract RSVPs directly from JSON (no extra queries!)
      // The view already returns going_users, not_going_users, no_response_users
      final events = <GroupEventEntity>[];
      for (final json in jsonList) {
        // Extract RSVPs from the JSON itself instead of fetching separately
        final rsvps = _extractRsvpsFromJson(json);
        events.add(GroupEventModel.fromJson(json, rsvps: rsvps));
      }

      return events;
    } catch (e) {
      return [];
    }
  }

  /// Extract RSVPs from the JSON response (going_users, not_going_users, no_response_users)
  /// This avoids N+1 queries by using data already in the response
  List<Map<String, dynamic>> _extractRsvpsFromJson(Map<String, dynamic> json) {
    final allVotes = <Map<String, dynamic>>[];

    // Parse going users
    final goingUsers = json['going_users'] as List? ?? [];
    for (final user in goingUsers) {
      if (user is Map<String, dynamic>) {
        allVotes.add({
          'user_id': user['user_id'] ?? '',
          'user_name': user['full_name'] ??
              user['display_name'] ??
              user['name'] ??
              'User',
          'user_avatar': user['avatar_url'],
          'status': 'yes',
          'voted_at': user['voted_at'],
        });
      }
    }

    // Parse not going users
    final notGoingUsers = json['not_going_users'] as List? ?? [];
    for (final user in notGoingUsers) {
      if (user is Map<String, dynamic>) {
        allVotes.add({
          'user_id': user['user_id'] ?? '',
          'user_name': user['full_name'] ??
              user['display_name'] ??
              user['name'] ??
              'User',
          'user_avatar': user['avatar_url'],
          'status': 'notGoing',
          'voted_at': user['voted_at'],
        });
      }
    }

    // Parse no response users
    final noResponseUsers = json['no_response_users'] as List? ?? [];
    for (final user in noResponseUsers) {
      if (user is Map<String, dynamic>) {
        allVotes.add({
          'user_id': user['user_id'] ?? '',
          'user_name': user['full_name'] ??
              user['display_name'] ??
              user['name'] ??
              'User',
          'user_avatar': user['avatar_url'],
          'status': 'pending',
          'voted_at': null,
        });
      }
    }

    return allVotes;
  }

  @override
  Future<int> getGroupEventsCount(String groupId) {
    return _dataSource.getGroupEventsCount(groupId);
  }

  @override
  Future<GroupEventEntity?> getEventById(String eventId) async {
    try {
      final json = await _dataSource.getEventById(eventId);
      if (json == null) {
        return null;
      }

      // Extract RSVPs from the JSON itself
      final rsvps = _extractRsvpsFromJson(json);

      return GroupEventModel.fromJson(json, rsvps: rsvps);
    } catch (e) {
      return null;
    }
  }
}
