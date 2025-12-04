import '../../domain/entities/report_entity.dart';

/// Data Transfer Object for Report
/// Maps between Supabase JSON and domain entity
class ReportModel {
  final String? id;
  final String userId;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReportModel({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create ReportModel from Supabase JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert ReportModel to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Convert to domain entity
  ReportEntity toEntity() {
    return ReportEntity(
      id: id,
      userId: userId,
      category: category,
      description: description,
      status: status,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory ReportModel.fromEntity(ReportEntity entity) {
    return ReportModel(
      id: entity.id,
      userId: entity.userId,
      category: entity.category,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}
