import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for group details from Supabase
class GroupDetailsDataSource {
  final SupabaseClient _supabase;

  GroupDetailsDataSource(this._supabase);

  /// Get group details including permissions
  Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    try {
      final response = await _supabase
          .from('groups')
          .select('''
            id,
            name,
            photo_url,
            members_can_invite,
            members_can_add_members,
            members_can_create_events
          ''')
          .eq('id', groupId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to load group details: $e');
    }
  }

  /// Get member count for a group
  Future<int> getGroupMemberCount(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .count();

      return response.count;
    } catch (e) {
      throw Exception('Failed to count group members: $e');
    }
  }

  /// Check if current user is admin of the group
  Future<bool> isCurrentUserAdmin(String groupId, String userId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return false;
      
      return response['role'] == 'admin';
    } catch (e) {
      throw Exception('Failed to check admin status: $e');
    }
  }

  /// Check if group is muted for current user
  Future<bool> isGroupMuted(String groupId, String userId) async {
    try {
      final response = await _supabase
          .from('group_user_settings')
          .select('is_muted')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return false;
      
      return response['is_muted'] as bool? ?? false;
    } catch (e) {
      // If settings don't exist, group is not muted
      return false;
    }
  }
}
