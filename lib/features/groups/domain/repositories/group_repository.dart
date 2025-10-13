import '../entities/group.dart';
import '../entities/group_entity.dart';
import 'package:image_picker/image_picker.dart';

/// Interface do repositório de grupos
abstract class GroupRepository {
  /// Obtém todos os grupos do usuário (apenas ativos)
  Future<List<Group>> getUserGroups();

  /// Obtém grupos arquivados do usuário
  Future<List<Group>> getArchivedGroups();

  /// Busca grupos por termo
  Future<List<Group>> searchGroups(String searchTerm);

  /// Obtém um grupo específico por ID
  Future<Group?> getGroupById(String groupId);

  /// Cria um novo grupo (original interface)
  Future<Group> createGroup({
    required String name,
    String? photoPath,  // atualizado de avatarUrl para photoPath
    List<String>? memberIds,
  });

  /// Cria um novo grupo (nova interface para create_group feature)
  Future<GroupEntity> createGroupEntity(GroupEntity group);

  /// Upload de foto de capa do grupo com compressão WebP
  /// Retorna o path do arquivo no storage (não URL)
  Future<String> uploadGroupCoverPhoto(XFile imageFile, String groupId);

  /// Obtém signed URL para foto de capa do grupo
  /// Cache busting usando photoUpdatedAt
  Future<String?> getGroupCoverUrl(String? photoPath, DateTime? photoUpdatedAt);

  /// Salva o QR code do grupo no Supabase
  Future<void> saveGroupQrCode(String groupId, String qrCodeData);

  /// Convida membros para o grupo
  Future<void> inviteMembers(String groupId, List<String> memberIds);

  /// Remove o usuário do grupo
  Future<void> leaveGroup(String groupId);

  /// Alterna o status de mute do grupo
  Future<void> toggleMute(String groupId, bool isMuted);

  /// Alterna o status de pin do grupo
  Future<void> togglePin(String groupId);

  /// Alterna o status de arquivo do grupo
  Future<void> toggleArchive(String groupId);

  /// Obtém membros do grupo
  Future<List<String>> getGroupMembers(String groupId);
}
