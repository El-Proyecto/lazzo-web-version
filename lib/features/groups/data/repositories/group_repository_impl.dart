import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/group_permissions.dart';
import '../../domain/repositories/group_repository.dart';
import '../data_sources/groups_data_source.dart';
import '../models/group_entity_model.dart';
import '../../../../shared/models/group_enums.dart';
import '../../../../shared/utils/image_compression_service.dart';

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

      // Converter entidade para formato do data source (nova estrutura)
      final groupData = GroupEntityModel.toDataSourceFormat(group, user.id);
      
      // Gerar QR code e group URL desde a criação
      final tempGroupId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final qrCodeData = 'https://lazzo.app/groups/$tempGroupId';
      groupData['qr_code'] = qrCodeData;
      groupData['group_url'] = qrCodeData;
      
      print('🎯 Creating group with initial QR code: $qrCodeData');
      
      // Preparar dados com nova estrutura photo_path/photo_updated_at
      if (group.photoUrl != null && group.photoUrl!.isNotEmpty) {
        // Se é um caminho local, sinalizar que precisa de upload
        if (!group.photoUrl!.startsWith('http')) {
          // Será processado após criação do grupo
          groupData['needs_photo_upload'] = true;
          groupData['temp_photo_path'] = group.photoUrl;
        } else {
          // Se já é URL, deixar campos nulos por enquanto
          groupData['photo_url'] = null;
          groupData['photo_updated_at'] = null;
        }
      } else {
        groupData['photo_url'] = null;
        groupData['photo_updated_at'] = null;
      }

      // Criar grupo
      final createdGroupData = await _dataSource.createGroup(user.id, groupData);
      
      // Atualizar QR code com ID real
      final realGroupId = createdGroupData['id'].toString();
      final realQrCodeData = 'https://lazzo.app/groups/$realGroupId';
      
      print('🔄 Updating QR code with real group ID: $realGroupId');
      await _dataSource.saveGroupQrCode(realGroupId, realQrCodeData);
      
      // Se precisamos fazer upload da foto, fazer agora com ID correto
      if (groupData['needs_photo_upload'] == true) {
        final imageFile = XFile(groupData['temp_photo_path']);
        await uploadGroupCoverPhoto(imageFile, realGroupId);
        
        // Recarregar dados atualizados
        final updatedGroups = await _dataSource.getUserGroups(user.id);
        final updatedGroup = updatedGroups.firstWhere(
          (g) => g['id'] == createdGroupData['id'],
        );
        
        // Certificar que tem QR code atualizado
        updatedGroup['qr_code'] = realQrCodeData;
        updatedGroup['group_url'] = realQrCodeData;
        
        return GroupEntityModel.fromJson(updatedGroup);
      }

      // Certificar que a resposta tem QR code atualizado
      createdGroupData['qr_code'] = realQrCodeData;
      createdGroupData['group_url'] = realQrCodeData;
      
      // Converter resposta para entidade
      return GroupEntityModel.fromJson(createdGroupData);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  @override
  Future<String> uploadGroupCoverPhoto(XFile imageFile, String groupId) async {
    try {
      print('🚀 Starting group cover photo upload process');
      
      // 1) Comprimir imagem para WebP
      final compressedBytes = await ImageCompressionService.compressToWebP(imageFile);
      
      // 2) Upload para bucket privado
      final photoPath = await _dataSource.uploadGroupCoverPhoto(compressedBytes, groupId);
      
      print('✅ Group cover photo upload completed: $photoPath');
      return photoPath;
    } catch (e) {
      print('❌ Group cover photo upload failed: $e');
      throw Exception('Failed to upload group cover photo: $e');
    }
  }

  @override
  Future<String?> getGroupCoverUrl(String? photoPath, DateTime? photoUpdatedAt) async {
    if (photoPath == null || photoPath.isEmpty) {
      return null;
    }

    try {
      // Cache busting: incluir timestamp no processo para verificar se URL ainda é válida
      // Por simplicidade, sempre geramos nova signed URL
      final signedUrl = await _dataSource.getGroupCoverSignedUrl(photoPath);
      
      // Adicionar timestamp como query param para cache busting
      final timestamp = photoUpdatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
      final urlWithCacheBuster = signedUrl.contains('?') 
          ? '$signedUrl&t=$timestamp'
          : '$signedUrl?t=$timestamp';
      
      return urlWithCacheBuster;
    } catch (e) {
      print('⚠️ Failed to get group cover URL: $e');
      return null;
    }
  }

  @override
  Future<void> saveGroupQrCode(String groupId, String qrCodeData) async {
    try {
      print('📋 [Repository] Saving QR code for group: $groupId');
      await _dataSource.saveGroupQrCode(groupId, qrCodeData);
      print('   ✅ [Repository] QR code save completed');
    } catch (e) {
      print('   ❌ [Repository] Failed to save QR code: $e');
      throw Exception('Failed to save QR code: $e');
    }
  }

  @override
  Future<List<Group>> getUserGroups() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return [];
      }

      final groupsData = await _dataSource.getUserGroups(user.id);
      
      // Converter para o formato Group existente usando nova estrutura
      return groupsData.map((data) {
        // Parse photo_updated_at se existe
        DateTime? photoUpdatedAt;
        if (data['photo_updated_at'] != null) {
          photoUpdatedAt = DateTime.parse(data['photo_updated_at'] as String);
        }

        return Group(
          id: data['id'].toString(),
          name: data['name'] as String,
          photoPath: data['photo_url'] as String?, // novo campo
          photoUpdatedAt: photoUpdatedAt, // novo campo
          // avatarUrl será calculado dinamicamente via getGroupCoverUrl
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
    String? photoPath,  // atualizado de avatarUrl
    List<String>? memberIds,
  }) async {
    // Implementação usando a nova estrutura
    final groupEntity = GroupEntity(
      name: name,
      description: null,
      photoUrl: photoPath, // temporário - será migrado para photoPath
      permissions: const GroupPermissions(),
      createdAt: DateTime.now(),
    );

    final created = await createGroupEntity(groupEntity);
    
    // Converter para Group
    return Group(
      id: created.id.toString(),
      name: created.name,
      photoPath: null, // será definido após upload se necessário
      photoUpdatedAt: null,
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