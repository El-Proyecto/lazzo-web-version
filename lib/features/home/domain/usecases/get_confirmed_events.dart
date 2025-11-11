import '../entities/home_event.dart';
import '../repositories/home_event_repository.dart';

/// Use case to get confirmed events for home page
class GetConfirmedEvents {
  final HomeEventRepository repository;

  GetConfirmedEvents(this.repository);

  Future<List<HomeEventEntity>> call() async {
    return await repository.getConfirmedEvents();
  }
}
