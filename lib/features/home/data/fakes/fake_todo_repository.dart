import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import 'fake_home_event_repository.dart';

/// Fake repository for to-dos - used for UI development
/// Returns mock data without backend calls
class FakeTodoRepository implements TodoRepository {
  @override
  Future<List<TodoEntity>> getTodos() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if we're in no-events state (todos are related to events)
    if (FakeHomeEventRepository.mockEmptyState == 'no-events') {
      return []; // Return empty list when there are no events
    }

    final now = DateTime.now();

    final todos = [
      TodoEntity(
        id: 'todo_1',
        actionName: 'Vote a date',
        eventEmoji: '🍽️',
        eventName: 'Friday Dinner',
        groupName: 'Dinner Group',
        deadline: now.add(const Duration(hours: 18)), // 18h left
      ),
      TodoEntity(
        id: 'todo_2',
        actionName: 'Confirm attendance',
        eventEmoji: '🏖️',
        eventName: 'Beach BBQ',
        groupName: 'Beach Friends',
        deadline: now.add(const Duration(days: 2)), // 2d left
      ),
      TodoEntity(
        id: 'todo_3',
        actionName: 'Add photos',
        eventEmoji: '🎂',
        eventName: 'Birthday Party',
        groupName: 'Party Crew',
        deadline: now.add(const Duration(hours: 3)), // 3h left (urgent)
      ),
      TodoEntity(
        id: 'todo_4',
        actionName: 'Vote a place',
        eventEmoji: '🎵',
        eventName: 'Concert Night',
        groupName: 'Music Lovers',
        deadline: now.add(const Duration(days: 5)), // 5d left
      ),
    ];

    // Sort by urgency (most urgent first - closest deadline)
    todos.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });

    return todos;
  }
}
