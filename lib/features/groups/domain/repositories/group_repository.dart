import '../entities/group.dart';
import '../entities/group_entity.dart';

/// Interface do repositório de grupos
abstract class GroupRepository {
  /// Obtém todos os grupos do usuário
  Future<List<Group>> getUserGroups();

  /// Busca grupos por termo
  Future<List<Group>> searchGroups(String searchTerm);

  /// Obtém um grupo específico por ID
  Future<Group?> getGroupById(String groupId);

  /// Cria um novo grupo (original interface)
  Future<Group> createGroup({
    required String name,
    String? avatarUrl,
    List<String>? memberIds,
  });

  /// Cria um novo grupo (nova interface para create_group feature)
  Future<GroupEntity> createGroupEntity(GroupEntity group);

  /// Uploads a group photo and returns the URL
  Future<String> uploadGroupPhoto(String imagePath, String groupId);

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
