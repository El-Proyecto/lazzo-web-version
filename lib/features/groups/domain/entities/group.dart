import '../../../../shared/models/group_enums.dart';

/// Entidade de domínio representando um grupo
class Group {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? lastActivity;
  final DateTime? lastActivityTime;
  final int? unreadCount;
  final int? openActionsCount;
  final int? addPhotosCount;
  final String? addPhotosTimeLeft; // Tempo restante para adicionar fotos
  final GroupStatus status;
  final bool isMuted;
  final bool isPinned; // Indica se o grupo está afixado
  final int memberCount;

  const Group({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastActivity,
    this.lastActivityTime,
    this.unreadCount,
    this.openActionsCount,
    this.addPhotosCount,
    this.addPhotosTimeLeft,
    required this.status,
    this.isMuted = false,
    this.isPinned = false,
    required this.memberCount,
  });

  /// Retorna a sub-linha contextual do grupo baseada na prioridade
  String get contextualSubline {
    // Para grupos arquivados, sempre mostrar "Last Event: " + lastActivity
    if (status == GroupStatus.archived) {
      if (lastActivity != null) {
        return "Last Event: ${lastActivity!}";
      }
      return "No previous events";
    }

    // Prioridade para grupos ativos: Open Actions > Add Photos > Last Activity
    if (openActionsCount != null && openActionsCount! > 0) {
      return _getOpenActionsText();
    }

    if (addPhotosCount != null && addPhotosCount! > 0) {
      return _getAddPhotosText();
    }

    if (lastActivity != null) {
      return lastActivity!;
    }

    return "No events — create one";
  }

  /// Calcula a urgência baseada no tempo restante
  BadgeUrgency get urgency {
    if (openActionsCount != null && openActionsCount! > 0) {
      return BadgeUrgency
          .high; // Exemplo - seria calculado baseado no tempo real
    }
    if (addPhotosCount != null && addPhotosCount! > 0) {
      return BadgeUrgency.medium;
    }
    return BadgeUrgency.none;
  }

  String _getOpenActionsText() {
    return "Vote date · closes Tue"; // Placeholder - seria dinâmico
  }

  String _getAddPhotosText() {
    return "Add photos · 12h left"; // Placeholder - seria dinâmico
  }
}
