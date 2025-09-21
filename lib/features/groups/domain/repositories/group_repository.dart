import '../entities/group.dart';

/// Interface do repositório de grupos
abstract class GroupRepository {
  /// Obtém todos os grupos do usuário
  Future<List<Group>> getUserGroups();

  /// Busca grupos por termo
  Future<List<Group>> searchGroups(String searchTerm);

  /// Obtém um grupo específico por ID
  Future<Group?> getGroupById(String groupId);

  /// Cria um novo grupo
  Future<Group> createGroup({
    required String name,
    String? avatarUrl,
    List<String>? memberIds,
  });

  /// Convida membros para o grupo
  Future<void> inviteMembers(String groupId, List<String> memberIds);

  /// Remove o usuário do grupo
  Future<void> leaveGroup(String groupId);

  /// Alterna o status de mute do grupo
  Future<void> toggleMute(String groupId, bool isMuted);

  /// Obtém membros do grupo
  Future<List<String>> getGroupMembers(String groupId);
}
