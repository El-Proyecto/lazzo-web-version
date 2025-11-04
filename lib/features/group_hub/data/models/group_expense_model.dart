import '../../domain/entities/group_expense_entity.dart';

class GroupExpenseDto {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy;
  final List<String> participantsOwe;
  final List<String> participantsPaid;
  final DateTime createdAt;
  final bool isSettled;

  const GroupExpenseDto({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.participantsOwe,
    required this.participantsPaid,
    required this.createdAt,
    required this.isSettled,
  });

  /// Parse Supabase row -> DTO
  factory GroupExpenseDto.fromJson(Map<String, dynamic> json) {
    return GroupExpenseDto(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paid_by'] as String,
      participantsOwe: List<String>.from(json['participants_owe'] ?? []),
      participantsPaid: List<String>.from(json['participants_paid'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      isSettled: json['is_settled'] as bool? ?? false,
    );
  }

  /// DTO -> Entity
  GroupExpenseEntity toEntity() {
    return GroupExpenseEntity(
      id: id,
      groupId: groupId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      participantsOwe: participantsOwe,
      participantsPaid: participantsPaid,
      date: createdAt,
      isSettled: isSettled,
    );
  }

  /// Entity -> JSON (para INSERT)
  static Map<String, dynamic> fromEntity(GroupExpenseEntity entity) {
    return {
      'group_id': entity.groupId,
      'description': entity.description,
      'amount': entity.amount,
      'participants_owe': entity.participantsOwe,
      'participants_paid': entity.participantsPaid,
      'is_settled': entity.isSettled,
    };
  }
}