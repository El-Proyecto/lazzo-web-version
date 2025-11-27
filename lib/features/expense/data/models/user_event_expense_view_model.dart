import '../../domain/entities/event_expense_entity.dart';

/// DTO for user_event_expenses view
/// This view aggregates expense data with user participation info
class UserEventExpenseViewDto {
  final String expenseId;
  final String eventId;
  final String title;
  final double totalAmount;
  final String paidByUserId;
  final DateTime createdAt;

  // User-specific fields
  final String participantId;
  final double? participantAmount; // NULL if not_related
  final bool? participantHasPaid; // NULL if not_related
  final String userRole; // 'payer', 'participant', 'not_related'
  final int totalParticipants;

  const UserEventExpenseViewDto({
    required this.expenseId,
    required this.eventId,
    required this.title,
    required this.totalAmount,
    required this.paidByUserId,
    required this.createdAt,
    required this.participantId,
    this.participantAmount,
    this.participantHasPaid,
    required this.userRole,
    required this.totalParticipants,
  });

  factory UserEventExpenseViewDto.fromJson(Map<String, dynamic> json) {
    return UserEventExpenseViewDto(
      expenseId: json['expense_id'] as String,
      eventId: json['event_id'] as String,
      title: json['title'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidByUserId: json['paid_by_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      participantId: json['participant_id'] as String,
      participantAmount: json['participant_amount'] != null
          ? (json['participant_amount'] as num).toDouble()
          : null,
      participantHasPaid: json['participant_has_paid'] as bool?,
      userRole: json['user_role'] as String,
      totalParticipants: json['total_participants'] as int,
    );
  }

  /// Convert to entity
  /// Note: This creates a partial entity focused on current user's perspective
  EventExpenseEntity toEntity() {
    // For participantsOwe, we need to aggregate all participants
    // But the view only shows current user's row
    // So we'll mark participantsOwe based on user role
    final participantsOwe =
        userRole != 'not_related' ? [participantId] : <String>[];

    return EventExpenseEntity(
      id: expenseId,
      eventId: eventId,
      description: title,
      amount: totalAmount,
      paidBy: paidByUserId,
      participantsOwe: participantsOwe,
      participantsPaid: participantHasPaid == true ? [participantId] : [],
      date: createdAt,
      isSettled: false, // TODO: Add to view if needed
    );
  }

  /// Helper: Check if current user is the payer
  bool get isPayer => userRole == 'payer';

  /// Helper: Check if current user is related to expense
  bool get isRelated => userRole != 'not_related';

  /// Helper: Get amount for current user (0 if not related)
  double get userAmount => participantAmount ?? 0.0;

  /// Helper: Check if current user has paid
  bool get userHasPaid => participantHasPaid ?? false;
}
