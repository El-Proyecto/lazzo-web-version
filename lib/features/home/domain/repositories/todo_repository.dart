import '../entities/todo_entity.dart';

/// Repository interface for user's to-dos
abstract class TodoRepository {
  /// Get all pending to-dos for the current user
  Future<List<TodoEntity>> getTodos();
}
