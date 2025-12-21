import '../entities/home_event.dart';
import '../repositories/home_event_repository.dart';

/// Use case to get all living and recap events sorted by time remaining
class GetLivingAndRecapEvents {
  final HomeEventRepository repository;

  GetLivingAndRecapEvents(this.repository);

  Future<List<HomeEventEntity>> call() async {
    return await repository.getLivingAndRecapEvents();
  }
}
