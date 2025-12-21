import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_expense_paid_from_notification.dart';
import '../../../expense/presentation/providers/event_expense_providers.dart';

// Repository provider - overridden in main.dart with real Supabase implementation
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  throw UnimplementedError('NotificationRepository must be overridden in main.dart');
});

// Use case providers
final getNotificationsUseCaseProvider = Provider<GetNotifications>((ref) {
  return GetNotifications(ref.watch(notificationRepositoryProvider));
});

final markNotificationAsReadUseCaseProvider = Provider<MarkNotificationAsRead>((
  ref,
) {
  return MarkNotificationAsRead(ref.watch(notificationRepositoryProvider));
});

final markExpenseAsPaidFromNotificationUseCaseProvider = Provider<MarkExpenseAsPaidFromNotification>((ref) {
  return MarkExpenseAsPaidFromNotification(
    notificationRepository: ref.watch(notificationRepositoryProvider),
    expenseRepository: ref.watch(eventExpenseRepositoryProvider),
    supabase: Supabase.instance.client,
  );
});

final getUnreadNotificationCountUseCaseProvider =
    Provider<GetUnreadNotificationCount>((ref) {
      return GetUnreadNotificationCount(
        ref.watch(notificationRepositoryProvider),
      );
    });

// State providers
final notificationsProvider =
    StateNotifierProvider<
      NotificationsController,
      AsyncValue<List<NotificationEntity>>
    >((ref) {
      return NotificationsController(
        ref.watch(getNotificationsUseCaseProvider),
      );
    });

final unreadCountProvider =
    StateNotifierProvider<UnreadCountController, AsyncValue<int>>((ref) {
      return UnreadCountController(
        ref.watch(getUnreadNotificationCountUseCaseProvider),
      );
    });

class NotificationsController
    extends StateNotifier<AsyncValue<List<NotificationEntity>>> {
  final GetNotifications _getNotifications;

  NotificationsController(this._getNotifications)
    : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    print('[NotificationsController] 🚀 loadNotifications called');
    state = const AsyncValue.loading();
    
    try {
      print('[NotificationsController] 🔄 Calling use case...');
      final notifications = await _getNotifications();
      
      print('[NotificationsController] ✅ Got ${notifications.length} notifications');
      if (notifications.isNotEmpty) {
        print('[NotificationsController] First notification: ${notifications.first.type}');
      }
      
      state = AsyncValue.data(notifications);
      print('[NotificationsController] ✅ State updated to data');
    } catch (error, stackTrace) {
      print('[NotificationsController] ❌ ERROR: $error');
      print('[NotificationsController] Error type: ${error.runtimeType}');
      print('[NotificationsController] Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }
}

class UnreadCountController extends StateNotifier<AsyncValue<int>> {
  final GetUnreadNotificationCount _getUnreadCount;

  UnreadCountController(this._getUnreadCount)
    : super(const AsyncValue.loading()) {
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    state = const AsyncValue.loading();
    try {
      final count = await _getUnreadCount();
      state = AsyncValue.data(count);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadUnreadCount();
  }
}
