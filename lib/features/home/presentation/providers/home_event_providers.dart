import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/home_event_repository.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/usecases/get_next_event.dart';
import '../../domain/usecases/get_confirmed_events.dart';
import '../../domain/usecases/get_home_pending_events.dart';
import '../../domain/usecases/get_todos.dart';
import '../../data/fakes/fake_home_event_repository.dart';
import '../../data/fakes/fake_todo_repository.dart';

// Repository providers - default to fake implementations
final homeEventRepositoryProvider = Provider<HomeEventRepository>((ref) {
  return FakeHomeEventRepository();
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return FakeTodoRepository();
});

// Use case providers
final getNextEventProvider = Provider<GetNextEvent>((ref) {
  return GetNextEvent(ref.watch(homeEventRepositoryProvider));
});

final getConfirmedEventsProvider = Provider<GetConfirmedEvents>((ref) {
  return GetConfirmedEvents(ref.watch(homeEventRepositoryProvider));
});

final getHomePendingEventsProvider = Provider<GetHomePendingEvents>((ref) {
  return GetHomePendingEvents(ref.watch(homeEventRepositoryProvider));
});

final getTodosProvider = Provider<GetTodos>((ref) {
  return GetTodos(ref.watch(todoRepositoryProvider));
});

// Controller providers that expose AsyncValue for UI
final nextEventControllerProvider =
    FutureProvider<HomeEventEntity?>((ref) async {
  final useCase = ref.watch(getNextEventProvider);
  return await useCase();
});

final confirmedEventsControllerProvider =
    FutureProvider<List<HomeEventEntity>>((ref) async {
  final useCase = ref.watch(getConfirmedEventsProvider);
  return await useCase();
});

final homePendingEventsControllerProvider =
    FutureProvider<List<HomeEventEntity>>((ref) async {
  final useCase = ref.watch(getHomePendingEventsProvider);
  return await useCase();
});

final todosControllerProvider = FutureProvider<List<TodoEntity>>((ref) async {
  final useCase = ref.watch(getTodosProvider);
  return await useCase();
});
