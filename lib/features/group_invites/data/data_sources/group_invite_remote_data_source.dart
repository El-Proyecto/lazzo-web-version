import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_invite_link_model.dart';

class GroupInviteRemoteDataSource {
  final SupabaseClient _client;

  GroupInviteRemoteDataSource(this._client);

  Future<GroupInviteLinkModel> createInviteLink({
    required String groupId,
    int? maxUses,
    int expiresInHours = 48,
  }) async {
    final response = await _client.rpc(
      'create_group_invite_link',
      params: {
        'p_group_id': groupId,
        'p_max_uses': maxUses,
        'p_expires_in_hours': expiresInHours,
      },
    );

    if (response is List && response.isNotEmpty) {
      final data = response.first as Map<String, dynamic>;
      return GroupInviteLinkModel.fromJson(data);
    }

    throw Exception('Failed to create invite link');
  }

  Future<String> acceptInviteByToken(String token) async {
    final response = await _client.rpc(
      'accept_group_invite_by_token',
      params: {'p_token': token},
    );

    if (response is String && response.isNotEmpty) {
      return response;
    }

    throw Exception('Failed to accept invite');
  }
}
