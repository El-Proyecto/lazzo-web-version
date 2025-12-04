import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event_history.dart';
import '../../domain/usecases/get_user_event_history.dart';
import 'event_providers.dart';

/// Provider for getting user event history for template reuse
/// Uses family pattern to cache results per userId
final eventHistoryProvider =
    FutureProvider.family<List<EventHistory>, String>((ref, userId) async {
  final repository = ref.watch(eventRepositoryProvider);
  final useCase = GetUserEventHistory(repository);
  return useCase(userId: userId, limit: 10);
});
