import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Data source for group operations with Supabase
abstract class GroupsDataSource {
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData);
  Future<String?> uploadGroupPhoto(String imagePath, String groupId);
  Future<List<Map<String, dynamic>>> getUserGroups(String userId);
}

class SupabaseGroupsDataSource implements GroupsDataSource {
  final SupabaseClient _client;

  SupabaseGroupsDataSource(this._client);

  @override
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData) async {
    try {
      // Insere o grupo na tabela groups
      final response = await _client
          .from('groups')
          .insert({
            'name': groupData['name'],
            //'description': groupData['description'],
            'photo_url': groupData['photo_url'],
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
            // Permissões armazenadas como campos separados
            'members_can_invite': groupData['members_can_invite'] ?? false,
            'members_can_add_members': groupData['members_can_add_members'] ?? false,
            'members_can_create_events': groupData['members_can_create_events'] ?? false,
          })
          .select()
          .single();

      // Adiciona o criador como membro do grupo
      await _client
          .from('group_members')
          .insert({
            'group_id': response['id'],
            'user_id': userId,
            'role': 'admin',
            'joined_at': DateTime.now().toIso8601String(),
          });

      return response;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  @override
  Future<String?> uploadGroupPhoto(String imagePath, String groupId) async {
    try {
      final fileName = 'group_$groupId.jpg';
      final path = 'groups/$groupId/$fileName';
      
      final file = File(imagePath);
      await _client.storage
          .from('group-photos')
          .upload(path, file);

      final publicUrl = _client.storage
          .from('group-photos')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      // Se falhar upload, continua sem foto
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    try {
      // STEP 1: Busca os IDs dos grupos onde o usuário é membro
      final memberResponse = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      if (memberResponse.isEmpty) {
        return [];
      }

      // Extrai apenas os IDs dos grupos
      final groupIds = memberResponse
          .map((member) => member['group_id'] as String)
          .toList();

      // STEP 2: Busca os detalhes dos grupos usando os IDs (sem JOIN)
      final groupsResponse = await _client
          .from('groups')
          .select('''
            id,
            name,
            photo_url,
            created_by,
            created_at,
            members_can_invite,
            members_can_add_members,
            members_can_create_events
          ''')
          .filter('id', 'in', '(${groupIds.join(',')})')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(groupsResponse);
    } catch (e) {
      throw Exception('Failed to fetch user groups: $e');
    }
  }
}