import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/usecases/get_user_activities.dart';
import '../../data/fakes/fake_activity_repository.dart';

// Repository provider - defaults to fake
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return FakeActivityRepository();
});

// Use case providers
final getUserActivitiesUseCaseProvider = Provider<GetUserActivities>((ref) {
  return GetUserActivities(ref.watch(activityRepositoryProvider));
});

final getActivitiesByTimeLeftUseCaseProvider =
    Provider<GetActivitiesByTimeLeft>((ref) {
      return GetActivitiesByTimeLeft(ref.watch(activityRepositoryProvider));
    });

final completeActivityUseCaseProvider = Provider<CompleteActivity>((ref) {
  return CompleteActivity(ref.watch(activityRepositoryProvider));
});

// State providers
final activitiesProvider =
    StateNotifierProvider<
      ActivitiesController,
      AsyncValue<List<ActivityEntity>>
    >((ref) {
      return ActivitiesController(
        ref.watch(getActivitiesByTimeLeftUseCaseProvider),
      );
    });

class ActivitiesController
    extends StateNotifier<AsyncValue<List<ActivityEntity>>> {
  final GetActivitiesByTimeLeft _getActivitiesByTimeLeft;

  ActivitiesController(this._getActivitiesByTimeLeft)
    : super(const AsyncValue.loading()) {
    loadActivities();
  }

  Future<void> loadActivities() async {
    state = const AsyncValue.loading();
    try {
      final allActivities = await _getActivitiesByTimeLeft();
      // Filter out payment activities - they go to payments section
      final filteredActivities = allActivities
          .where(
            (activity) =>
                activity.type != ActivityType.payment &&
                activity.dueDate != null,
          ) // Only show activities with deadlines
          .toList();
      state = AsyncValue.data(filteredActivities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadActivities();
  }
}
