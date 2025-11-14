import '../entities/home_event.dart';
import '../repositories/home_event_repository.dart';

/// Use case to get the next upcoming event
class GetNextEvent {
  final HomeEventRepository repository;

  GetNextEvent(this.repository);

  Future<HomeEventEntity?> call() async {
    return await repository.getNextEvent();
  }
}
