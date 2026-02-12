import '../repositories/notification_repository.dart';
//import '../../domain/entities/notification_entity.dart';
// LAZZO 2.0: Expense feature removed
// import '../../../expense/domain/repositories/event_expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Use case to mark an expense as paid based on a payment notification
/// LAZZO 2.0: Expense feature removed — this use case only marks notification as read
class MarkExpenseAsPaidFromNotification {
  final NotificationRepository notificationRepository;
  final SupabaseClient supabase;

  const MarkExpenseAsPaidFromNotification({
    required this.notificationRepository,
    required this.supabase,
  });

  Future<void> call(String notificationId) async {
    // 1. Get notification to extract expense_id
    final notification =
        await notificationRepository.getNotificationById(notificationId);

    if (notification == null) {
      throw Exception('Notification not found');
    }

    // 2. Mark notification as read (removes from inbox)
    // LAZZO 2.0: Expense marking removed — expenses feature deleted
    await notificationRepository.markAsRead(notificationId);
  }
}
