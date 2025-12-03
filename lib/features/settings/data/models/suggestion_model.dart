import '../../domain/entities/suggestion_entity.dart';

/// Data Transfer Object for Suggestion
/// Maps between Supabase JSON and domain entity
class SuggestionModel {
  final String? id;
  final String userId;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SuggestionModel({
    this.id,
    required this.userId,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create SuggestionModel from Supabase JSON
  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert SuggestionModel to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Convert to domain entity
  SuggestionEntity toEntity() {
    return SuggestionEntity(
      id: id,
      userId: userId,
      description: description,
      status: status,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory SuggestionModel.fromEntity(SuggestionEntity entity) {
    return SuggestionModel(
      id: entity.id,
      userId: entity.userId,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}
