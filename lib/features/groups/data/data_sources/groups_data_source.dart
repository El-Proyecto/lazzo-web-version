import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/utils/image_compression_service.dart';

/// Data source for group operations with Supabase
abstract class GroupsDataSource {
  Future<Map<String, dynamic>> createGroup(String userId, Map<String, dynamic> groupData);
  Future<String> uploadGroupCoverPhoto(Uint8List imageBytes, String groupId);
  Future<String> getGroupCoverSignedUrl(String photoPath);
  Future<void> saveGroupQrCode(String groupId, String qrCodeData);
  Future<void> updateGroupPhoto(String groupId, String photoPath);
  Future<List<Map<String, dynamic>>> getUserGroups(String userId);
  Future<List<Map<String, dynamic>>> getArchivedGroups(String userId);
  Future<void> leaveGroup(String groupId, String userId);
  Future<void> updateGroupMemberState(String groupId, String userId, String state);
  Future<void> toggleMute(String groupId, String userId, bool isMuted);
  Future<void> togglePin(String groupId, String userId, bool isPinned);
  Future<String> ensureStoragePath({required String input, required String groupId, String bucket});
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
            // Novos campos movidos para groups table
            'is_pinned': false,
            'is_muted': false,
            'group_state': 'active',
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

      print('✅ [DataSource] Group created successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ [DataSource] Failed to create group: $e');
      throw Exception('Failed to create group: $e');
    }
  }

  @override
  Future<String> uploadGroupCoverPhoto(Uint8List imageBytes, String groupId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$groupId/cover_$timestamp.webp';
      
      await _client.storage
          .from(_bucketName)
          .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(
            contentType: 'image/webp',
            upsert: true, // Permitir substituir foto existente
          ));
      
      print('✅ [DataSource] Group cover photo uploaded: $fileName');
      return fileName; // Retorna apenas o path, não a URL completa
    } catch (e) {
      print('❌ [DataSource] Failed to upload group cover photo: $e');
      throw Exception('Failed to upload group cover photo: $e');
    }
  }

  @override
  Future<String> getGroupCoverSignedUrl(String photoPath) async {
    try {
      print('🔗 [DataSource] Getting signed URL for: $photoPath');
      
      // Validate that it's a storage path, not a local path
      if (photoPath.startsWith('/') || photoPath.contains('cache') || photoPath.contains('data/user')) {
        print('   ❌ Invalid path detected (local path instead of storage path): $photoPath');
        throw Exception('Invalid photo path - local paths are not supported');
      }
      
      final signedUrl = await _client.storage
          .from(_bucketName)
          .createSignedUrl(photoPath, 3600); // 1 hora de validade
      
      print('   ✅ Signed URL created successfully');
      return signedUrl;
    } catch (e) {
      print('   ❌ Failed to create signed URL: $e');
      throw Exception('Failed to get signed URL: $e');
    }
  }

  /// Ensures the input path is a valid storage path, uploading local files if needed
  @override
  Future<String> ensureStoragePath({
    required String input,
    required String groupId,
    String bucket = 'group-photos',
  }) async {
    // 1) Already a URL?
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }

    // 2) Is local? Upload and return object path
    final isLocal = input.startsWith('/') ||
                    input.startsWith('file://') ||
                    input.startsWith('content://') ||
                    input.contains('/data/') ||
                    input.contains('cache');
    
    if (isLocal) {
      print('📤 Converting local path to storage path: $input');
      
      // Check if file exists
      final file = File(input.replaceFirst('file://', ''));
      if (!await file.exists()) {
        throw Exception('Local file does not exist: $input');
      }
      
      // Create XFile and compress using existing service
      final xFile = XFile(input);
      final compressedBytes = await ImageCompressionService.compressToWebP(xFile);
      
      // Create object path with timestamp for versioning
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final objectPath = 'groups/$groupId/cover_$timestamp.webp';
      
      // Upload to storage
      await _client.storage.from(bucket).uploadBinary(
        objectPath, 
        compressedBytes,
        fileOptions: const FileOptions(
          contentType: 'image/webp',
          upsert: true,
        ),
      );
      
      print('✅ Local file uploaded to storage: $objectPath');
      return objectPath; // Return just the object path
    }

    // 3) Looks like storage path (bucket/object or just object)
    if (RegExp(r'^[^/]+/.+').hasMatch(input)) {
      // If it includes bucket name, extract just the object path
      if (input.startsWith('$bucket/')) {
        return input.substring(bucket.length + 1);
      }
      return input;
    }

    throw Exception('Path não reconhecido: $input');
  }

  @override
  Future<void> saveGroupQrCode(String groupId, String qrCodeData) async {
    try {
      print('🔖 [DataSource] Saving QR code for group: $groupId');
      
      // Primeiro, tenta salvar qr_code e group_url
      await _client
          .from('groups')
          .update({
            'qr_code': qrCodeData,
            'group_url': 'https://lazzo.app/g/$groupId', // URL do grupo para compartilhamento
          })
          .eq('id', groupId);
      
      print('   ✅ QR code and group URL saved successfully');
    } catch (e) {
      // Se falhar, tenta salvar apenas o qr_code (para compatibilidade)
      if (e.toString().contains('group_url')) {
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
  Future<void> updateGroupPhoto(String groupId, String photoPath) async {
    try {
      print('📸 [DataSource] Updating group photo: $groupId -> $photoPath');
      
      await _client
          .from('groups')
          .update({
            'photo_url': photoPath,
            'photo_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', groupId);
      
      print('   ✅ Group photo updated successfully');
    } catch (e) {
      print('   ❌ Failed to update group photo: $e');
      throw Exception('Failed to update group photo: $e');
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

      // STEP 2: Busca os detalhes dos grupos usando os IDs (só grupos ativos)
      // Selecionando todos os campos incluindo qr_code, group_url, is_pinned, is_muted, group_state
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
            members_can_create_events,
            is_pinned,
            is_muted,
            group_state
          ''')
          .filter('id', 'in', '(${groupIds.join(',')})')
          .neq('group_state', 'archived') // Filtra grupos arquivados
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

      // STEP 2: Busca os detalhes dos grupos arquivados usando os IDs
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
            members_can_create_events,
            is_pinned,
            is_muted,
            group_state
          ''')
          .filter('id', 'in', '(${groupIds.join(',')})')
          .eq('group_state', 'archived') // Só grupos arquivados
          .order('created_at', ascending: false);

      print('   ✅ Found ${groupsResponse.length} archived groups');
      return List<Map<String, dynamic>>.from(groupsResponse);
    } catch (e) {
      print('   ❌ Failed to fetch archived groups: $e');
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
      print('📁 [DataSource] Updating group state: $state for group: $groupId');
      
      // Atualiza o group_state na tabela groups (não mais em group_members)
      await _client
          .from('groups')
          .update({'group_state': state})
          .eq('id', groupId);
      
      print('   ✅ Group state updated to: $state');
    } catch (e) {
      print('   ❌ Failed to update group state: $e');
      throw Exception('Failed to update group state: $e');
    }
  }

  @override
  Future<void> toggleMute(String groupId, String userId, bool isMuted) async {
    try {
      print('🔇 [DataSource] ${isMuted ? 'Muting' : 'Unmuting'} group: $groupId');
      
      // Atualiza o is_muted na tabela groups (não mais em group_members)
      await _client
          .from('groups')
          .update({'is_muted': isMuted})
          .eq('id', groupId);
      
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
      
      // Atualiza o is_pinned na tabela groups (não mais em group_members)
      await _client
          .from('groups')
          .update({'is_pinned': isPinned})
          .eq('id', groupId);
      
      print('   ✅ Group ${isPinned ? 'pinned' : 'unpinned'} successfully');
    } catch (e) {
      print('   ❌ Failed to toggle pin: $e');
      throw Exception('Failed to toggle pin: $e');
    }
  }
}