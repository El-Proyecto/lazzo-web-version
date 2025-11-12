import '../entities/home_event.dart';
import '../repositories/home_event_repository.dart';

/// Use case to get pending events for home page
class GetHomePendingEvents {
  final HomeEventRepository repository;

  GetHomePendingEvents(this.repository);

  Future<List<HomeEventEntity>> call() async {
    return await repository.getPendingEvents();
  }
}
