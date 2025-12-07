// 1. Criar entity de participante (se não existe)
// lib/features/event/domain/entities/event_participant_entity.dart

class EventParticipantEntity {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String status; // 'confirmed', 'pending', 'declined'

  const EventParticipantEntity({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.status,
  });
}