import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_permissions.dart';
import '../../domain/repositories/group_repository.dart';
import '../data_sources/groups_data_source.dart';
import '../models/group_entity_model.dart';
import '../../../../shared/models/group_enums.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupsDataSource _dataSource;
  final SupabaseClient _client;

  GroupRepositoryImpl(this._dataSource, this._client);

  @override
  Future<GroupEntity> createGroupEntity(GroupEntity group) async {
    try {
      // Obter usuário atual
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Converter entidade para formato do data source
      final groupData = GroupEntityModel.toDataSourceFormat(group, user.id);
      
      // Fazer upload da foto se fornecida
      String? photoUrl;
      if (group.photoUrl != null && group.photoUrl!.isNotEmpty) {
        // Se é um caminho local, fazer upload
        if (!group.photoUrl!.startsWith('http')) {
          photoUrl = await _dataSource.uploadGroupPhoto(group.photoUrl!, 'temp');
        } else {
          photoUrl = group.photoUrl;
        }
        groupData['photo_url'] = photoUrl;
      }

      // Criar grupo
      final createdGroupData = await _dataSource.createGroup(user.id, groupData);
      
      // Se tivemos que fazer upload da foto, atualizamos com o ID correto
      if (photoUrl != null && !group.photoUrl!.startsWith('http')) {
        final finalPhotoUrl = await _dataSource.uploadGroupPhoto(
          group.photoUrl!,
          createdGroupData['id'].toString(),
        );
        if (finalPhotoUrl != null) {
          createdGroupData['photo_url'] = finalPhotoUrl;
        }
      }

      // Converter resposta para entidade
      return GroupEntityModel.fromJson(createdGroupData);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  @override
  Future<String> uploadGroupPhoto(String imagePath, String groupId) async {
    final photoUrl = await _dataSource.uploadGroupPhoto(imagePath, groupId);
    return photoUrl ?? '';
  }

  // Implementações dos métodos existentes (mantendo compatibilidade)
  @override
  Future<List<Group>> getUserGroups() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return [];
      }

      final groupsData = await _dataSource.getUserGroups(user.id);
      
      // Converter para o formato Group existente
      return groupsData.map((data) {
        return Group(
          id: data['id'].toString(),
          name: data['name'] as String,
          avatarUrl: data['photo_url'] as String?,
          lastActivity: 'Created ${_formatDate(data['created_at'])}',
          lastActivityTime: data['created_at'] != null 
              ? DateTime.parse(data['created_at'] as String)
              : null,
          unreadCount: null,
          openActionsCount: null,
          addPhotosCount: null,
          addPhotosTimeLeft: null,
          status: GroupStatus.active,
          isPinned: false,
          memberCount: 1, // Por agora, apenas o criador
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user groups: $e');
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'recently';
    try {
      final date = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }

  @override
  Future<List<Group>> searchGroups(String searchTerm) async {
    // Por agora, retorna todos os grupos do usuário
    // Pode ser expandido para buscar grupos públicos
    return getUserGroups();
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final groups = await getUserGroups();
      return groups.where((g) => g.id == groupId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Group> createGroup({
    required String name,
    String? avatarUrl,
    List<String>? memberIds,
  }) async {
    // Implementação usando a nova estrutura
    final groupEntity = GroupEntity(
      name: name,
      description: null,
      photoUrl: avatarUrl,
      permissions: const GroupPermissions(),
      createdAt: DateTime.now(),
    );

    final created = await createGroupEntity(groupEntity);
    
    // Converter para Group
    return Group(
      id: created.id.toString(),
      name: created.name,
      avatarUrl: created.photoUrl,
      lastActivity: 'Just created',
      lastActivityTime: created.createdAt,
      unreadCount: null,
      openActionsCount: null,
      addPhotosCount: null,
      addPhotosTimeLeft: null,
      status: GroupStatus.active,
      isPinned: false,
      memberCount: 1,
    );
  }

  @override
  Future<void> inviteMembers(String groupId, List<String> memberIds) async {
    // TODO: Implementar convites
    throw UnimplementedError('Member invitations not implemented yet');
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  @override
  Future<void> toggleMute(String groupId, bool isMuted) async {
    // TODO: Implementar mute/unmute
    throw UnimplementedError('Mute/unmute not implemented yet');
  }

  @override
  Future<void> togglePin(String groupId) async {
    // TODO: Implementar pin/unpin
    throw UnimplementedError('Pin/unpin not implemented yet');
  }

  @override
  Future<void> toggleArchive(String groupId) async {
    // TODO: Implementar archive/unarchive
    throw UnimplementedError('Archive/unarchive not implemented yet');
  }

  @override
  Future<List<String>> getGroupMembers(String groupId) async {
    try {
      final response = await _client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      return response.map((row) => row['user_id'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get group members: $e');
    }
  }
}