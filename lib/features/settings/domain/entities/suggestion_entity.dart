/// Entity representing a user suggestion
class SuggestionEntity {
  final String? id;
  final String description;
  final String userId;
  final DateTime createdAt;
  final String status; // 'pending', 'in_review', 'implemented'

  const SuggestionEntity({
    this.id,
    required this.description,
    required this.userId,
    required this.createdAt,
    this.status = 'pending',
  });

  SuggestionEntity copyWith({
    String? id,
    String? description,
    String? userId,
    DateTime? createdAt,
    String? status,
  }) {
    return SuggestionEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'SuggestionEntity(id: $id, status: $status, userId: $userId)';
  }
}
