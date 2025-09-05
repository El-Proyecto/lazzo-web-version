// DTO

import '../../domain/entities/memory_summary.dart';

class MemorySummaryModel {
  final String id, title, emoji; final DateTime createdAt;
  const MemorySummaryModel({required this.id, required this.title, required this.emoji, required this.createdAt});

  factory MemorySummaryModel.fromMap(Map<String, dynamic> row) => MemorySummaryModel(
    id: row['id'] as String,
    title: row['title'] as String,
    emoji: row['emoji'] as String? ?? '🖼️',
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  MemorySummary toEntity() => MemorySummary(id: id, title: title, emoji: emoji, createdAt: createdAt);
}
