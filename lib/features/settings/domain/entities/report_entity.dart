/// Entity representing a problem report
class ReportEntity {
  final String? id;
  final String category;
  final String description;
  final String userId;
  final DateTime createdAt;
  final String status; // 'pending', 'in_review', 'resolved'

  const ReportEntity({
    this.id,
    required this.category,
    required this.description,
    required this.userId,
    required this.createdAt,
    this.status = 'pending',
  });

  ReportEntity copyWith({
    String? id,
    String? category,
    String? description,
    String? userId,
    DateTime? createdAt,
    String? status,
  }) {
    return ReportEntity(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
