import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/group_details_entity.dart';
import '../../domain/repositories/group_details_repository.dart';
import '../data_sources/group_details_data_source.dart';
import '../models/group_details_model.dart';
import '../../domain/entities/group_member_entity.dart';

/// Implementation of GroupDetailsRepository using Supabase
class GroupDetailsRepositoryImpl implements GroupDetailsRepository {
  final GroupDetailsDataSource _dataSource;
  final SupabaseClient _supabase;

  GroupDetailsRepositoryImpl(this._dataSource, this._supabase);

  @override
  Future<GroupDetailsEntity> getGroupDetails(String groupId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        _dataSource.getGroupDetails(groupId),
        _dataSource.getGroupMemberCount(groupId),
        _dataSource.isCurrentUserAdmin(groupId, currentUserId),
        _dataSource.isGroupMuted(groupId, currentUserId),
      ]);

      final groupData = results[0] as Map<String, dynamic>;
      final memberCount = results[1] as int;
      final isAdmin = results[2] as bool;
      final isMuted = results[3] as bool;

      final model = GroupDetailsModel.fromJson(
        groupData,
        memberCount: memberCount,
        isCurrentUserAdmin: isAdmin,
        isMuted: isMuted,
      );

      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to load group details: $e');
    }
  }

  @override
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('group_members')
          .select('''
            id,
            user_id,
            role,
            users:user_id (
              name,
              avatar_url
            )
          ''')
          .eq('group_id', groupId)
          .order('role', ascending: false); // Admins first

      final members = <GroupMemberEntity>[];
      
      for (final json in response as List) {
        final userId = json['user_id'] as String;
        final isCurrentUser = userId == currentUserId;
        final role = json['role'] as String;
        final isAdmin = role == 'admin';
        
        // Handle nested users join
        String? name;
        String? profileImageUrl;
        final users = json['users'];
        if (users != null) {
          if (users is Map<String, dynamic>) {
            name = users['name'] as String?;
            profileImageUrl = users['avatar_url'] as String?;
          } else if (users is List && users.isNotEmpty) {
            final firstUser = users[0] as Map<String, dynamic>;
            name = firstUser['name'] as String?;
            profileImageUrl = firstUser['avatar_url'] as String?;
          }
        }

        members.add(GroupMemberEntity(
          id: userId,
          name: name ?? 'Unknown',
          profileImageUrl: profileImageUrl,
          isAdmin: isAdmin,
          isCurrentUser: isCurrentUser,
        ));
      }

      // Sort: current user first, then admins, then members
      members.sort((a, b) {
        if (a.isCurrentUser) return -1;
        if (b.isCurrentUser) return 1;
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return 0;
      });

      return members;
    } catch (e) {
      throw Exception('Failed to load group members: $e');
    }
  }

  @override
  Future<void> toggleMute(String groupId, bool isMuted) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('group_user_settings')
          .upsert({
            'group_id': groupId,
            'user_id': currentUserId,
            'is_muted': isMuted,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to toggle mute: $e');
    }
  }
}
