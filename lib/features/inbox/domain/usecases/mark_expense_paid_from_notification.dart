import '../repositories/notification_repository.dart';
//import '../../domain/entities/notification_entity.dart';
import '../../../expense/domain/repositories/event_expense_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Use case to mark an expense as paid based on a payment notification
class MarkExpenseAsPaidFromNotification {
  final NotificationRepository notificationRepository;
  final EventExpenseRepository expenseRepository;
  final SupabaseClient supabase;

  const MarkExpenseAsPaidFromNotification({
    required this.notificationRepository,
    required this.expenseRepository,
    required this.supabase,
  });

  Future<void> call(String notificationId) async {
    // 1. Get notification to extract expense_id
    final notification = await notificationRepository.getNotificationById(notificationId);
    
    if (notification == null) {
      throw Exception('Notification not found');
    }

    // 2. Get current user ID
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // 3. Mark expense split as paid (if expenseId exists)
    if (notification.expenseId != null) {
      await expenseRepository.markExpenseAsPaid(
        expenseId: notification.expenseId!,
        userId: currentUserId,
      );
    }

    // 4. Mark notification as read (removes from inbox)
    await notificationRepository.markAsRead(notificationId);
  }
}
