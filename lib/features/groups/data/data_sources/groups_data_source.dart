import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

/// Data source for group operations with Supabase
abstract class GroupsDataSource {
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData);
  Future<String> uploadGroupCoverPhoto(Uint8List imageBytes, String groupId);
  Future<String> getGroupCoverSignedUrl(String photoPath);
  Future<void> saveGroupQrCode(String groupId, String qrCodeData);
  Future<List<Map<String, dynamic>>> getUserGroups(String userId);
  Future<List<Map<String, dynamic>>> getArchivedGroups(String userId);
  Future<void> leaveGroup(String groupId, String userId);
  Future<void> updateGroupMemberState(String groupId, String userId, String state);
  Future<void> toggleMute(String groupId, String userId, bool isMuted);
  Future<void> togglePin(String groupId, String userId, bool isPinned);
}

class SupabaseGroupsDataSource implements GroupsDataSource {
  final SupabaseClient _client;
  static const String _bucketName = 'group-photos'; // bucket para fotos de grupos

  SupabaseGroupsDataSource(this._client);

  @override
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData) async {
    try {
      // Insere o grupo na tabela groups com nova estrutura
      final response = await _client
          .from('groups')
          .insert({
            'name': groupData['name'],
            'photo_url': groupData['photo_url'], // novo campo - armazena apenas path
            'photo_updated_at': groupData['photo_updated_at'], // novo campo - timestamp
            'qr_code': groupData['qr_code'], // QR code data
            'group_url': groupData['group_url'], // Group URL for sharing
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
  Future<String> uploadGroupCoverPhoto(Uint8List imageBytes, String groupId) async {
    try {
      print('📤 [DataSource] Starting group cover photo upload for group: $groupId');
      print('   🗂️ Bucket name: $_bucketName');
      
      // 1) Gerar path único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cover_${timestamp}.webp';
      final path = 'groups/$groupId/$fileName';
      
      print('   📁 Upload path: $path');
      print('   📊 Image size: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
      
      // 2) Upload para bucket group-photos-private
      print('   📤 Uploading to Supabase Storage...');
      final uploadResponse = await _client.storage
          .from(_bucketName)
          .uploadBinary(path, imageBytes);
      
      print('   📦 Upload response: $uploadResponse');
      print('   ✅ Upload successful');
      
      // 3) Atualizar registro do grupo com novo path e timestamp
      print('   💾 Updating groups table...');
      final updateResponse = await _client
          .from('groups')
          .update({
            'photo_url': path,
            'photo_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', groupId)
          .select();
      
      print('   📦 Database update response: $updateResponse');
      print('   ✅ Database updated with photo metadata');
      
      return path;
    } catch (e) {
      print('   ❌ Upload failed: $e');
      print('   📍 Error type: ${e.runtimeType}');
      print('   📍 Error details: $e');
      throw Exception('Failed to upload group cover photo: $e');
    }
  }

  @override
  Future<String> getGroupCoverSignedUrl(String photoPath) async {
    try {
      print('🔗 Generating signed URL for: $photoPath');
      
      // Gerar signed URL com TTL de 1 hora
      final signedUrl = await _client.storage
          .from(_bucketName)
          .createSignedUrl(photoPath, 3600); // 3600 segundos = 1 hora
      
      print('   ✅ Signed URL generated (expires in 1h)');
      
      return signedUrl;
    } catch (e) {
      print('   ❌ Failed to generate signed URL: $e');
      throw Exception('Failed to generate signed URL: $e');
    }
  }

  @override
  Future<void> saveGroupQrCode(String groupId, String qrCodeData) async {
    try {
      print('💾 [DataSource] Saving QR code for group: $groupId');
      print('   📱 QR Code Data: $qrCodeData');
      
      // Gerar group_url baseado no QR code data
      final groupUrl = qrCodeData; // O QR code data já é a URL
      
      print('   🔗 Group URL: $groupUrl');
      print('   📤 Enviando update para Supabase...');
      
      // Primeiro vamos tentar buscar o grupo para verificar se existe
      final existingGroup = await _client
          .from('groups')
          .select('id, name')
          .eq('id', groupId)
          .maybeSingle();
      
      if (existingGroup == null) {
        throw Exception('Group with ID $groupId not found');
      }
      
      print('   ✅ Group found: ${existingGroup['name']}');
      
      // Atualizar registro do grupo com QR code e group_url
      final response = await _client
          .from('groups')
          .update({
            'qr_code': qrCodeData,
            'group_url': groupUrl,
          })
          .eq('id', groupId)
          .select();
      
      print('   📦 Supabase response: $response');
      print('   ✅ QR code and group URL saved successfully');
    } catch (e) {
      print('   ❌ Failed to save QR code: $e');
      print('   📍 Error details: ${e.runtimeType}');
      
      // Se for erro de schema, vamos tentar só salvar o qr_code
      if (e.toString().contains('column') && e.toString().contains('does not exist')) {
        print('   🔄 Tentando salvar apenas qr_code...');
        try {
          await _client
              .from('groups')
              .update({'qr_code': qrCodeData})
              .eq('id', groupId);
          print('   ✅ QR code saved (without group_url)');
        } catch (e2) {
          print('   ❌ Failed to save even qr_code: $e2');
          throw Exception('Failed to save QR code: $e2');
        }
      } else {
        throw Exception('Failed to save QR code: $e');
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    try {
      // STEP 1: Busca os IDs dos grupos onde o usuário é membro (só grupos ativos)
      final memberResponse = await _client
          .from('group_members')
          .select('group_id, group_state, is_muted, is_pinned')
          .eq('user_id', userId)
          .neq('group_state', 'archived'); // Filtra grupos arquivados

      if (memberResponse.isEmpty) {
        return [];
      }

      // Extrai apenas os IDs dos grupos
      final groupIds = memberResponse
          .map((member) => member['group_id'] as String)
          .toList();

      // STEP 2: Busca os detalhes dos grupos usando os IDs (sem JOIN)
      // Selecionando todos os campos incluindo qr_code e group_url
      final groupsResponse = await _client
          .from('groups')
          .select('''
            id,
            name,
            photo_url,
            photo_updated_at,
            qr_code,
            group_url,
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

  @override
  Future<List<Map<String, dynamic>>> getArchivedGroups(String userId) async {
    try {
      print('🗄️ Fetching archived groups for: $userId');

      // STEP 1: Busca os IDs dos grupos arquivados do usuário
      final memberResponse = await _client
          .from('group_members')
          .select('group_id, group_state, is_muted, is_pinned')
          .eq('user_id', userId)
          .eq('group_state', 'archived'); // Só grupos arquivados

      if (memberResponse.isEmpty) {
        return [];
      }

      // Extrai apenas os IDs dos grupos
      final groupIds = memberResponse
          .map((member) => member['group_id'] as String)
          .toList();

      // STEP 2: Busca os detalhes dos grupos arquivados
      final groupsResponse = await _client
          .from('groups')
          .select('''
            id,
            name,
            photo_url,
            photo_updated_at,
            qr_code,
            group_url,
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
      throw Exception('Failed to fetch archived groups: $e');
    }
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      print('👋 [DataSource] User leaving group: $groupId');
      
      // Remove o usuário da tabela group_members
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
      
      print('   ✅ User removed from group members');
    } catch (e) {
      print('   ❌ Failed to leave group: $e');
      throw Exception('Failed to leave group: $e');
    }
  }

  @override
  Future<void> updateGroupMemberState(String groupId, String userId, String state) async {
    try {
      print('📁 [DataSource] Updating group member state: $state for group: $groupId');
      
      // Atualiza o group_state na tabela group_members
      await _client
          .from('group_members')
          .update({'group_state': state})
          .eq('group_id', groupId)
          .eq('user_id', userId);
      
      print('   ✅ Group member state updated to: $state');
    } catch (e) {
      print('   ❌ Failed to update group state: $e');
      throw Exception('Failed to update group state: $e');
    }
  }

  @override
  Future<void> toggleMute(String groupId, String userId, bool isMuted) async {
    try {
      print('🔇 [DataSource] ${isMuted ? 'Muting' : 'Unmuting'} group: $groupId');
      
      // Atualiza o is_muted na tabela group_members
      await _client
          .from('group_members')
          .update({'is_muted': isMuted})
          .eq('group_id', groupId)
          .eq('user_id', userId);
      
      print('   ✅ Group ${isMuted ? 'muted' : 'unmuted'} successfully');
    } catch (e) {
      print('   ❌ Failed to toggle mute: $e');
      throw Exception('Failed to toggle mute: $e');
    }
  }

  @override
  Future<void> togglePin(String groupId, String userId, bool isPinned) async {
    try {
      print('📌 [DataSource] ${isPinned ? 'Pinning' : 'Unpinning'} group: $groupId');
      
      // Atualiza o is_pinned na tabela group_members
      await _client
          .from('group_members')
          .update({'is_pinned': isPinned})
          .eq('group_id', groupId)
          .eq('user_id', userId);
      
      print('   ✅ Group ${isPinned ? 'pinned' : 'unpinned'} successfully');
    } catch (e) {
      print('   ❌ Failed to toggle pin: $e');
      throw Exception('Failed to toggle pin: $e');
    }
  }
}