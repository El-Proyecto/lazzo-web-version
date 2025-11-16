// TODO P2: Remove this file - old memory summary model no longer used in new home structure
// DTO memory summary

import '../../domain/entities/memory_summary.dart';

class MemorySummaryModel {
  final String eventId, title, emoji;
  final DateTime createdAt;

  const MemorySummaryModel({
    required this.eventId,
    required this.title,
    required this.emoji,
    required this.createdAt,
  });

  factory MemorySummaryModel.fromMap(Map<String, dynamic> row) =>
      MemorySummaryModel(
        eventId: row['event_id'] as String,
        title: row['title'] as String,
        emoji: row['emoji'] as String? ?? '🖼️',
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  MemorySummary toEntity() => MemorySummary(
        eventId: eventId,
        title: title,
        emoji: emoji,
        createdAt: createdAt,
      );
}
