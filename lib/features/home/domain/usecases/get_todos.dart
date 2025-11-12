import '../entities/todo_entity.dart';
import '../repositories/todo_repository.dart';

/// Use case to get user's pending to-dos
class GetTodos {
  final TodoRepository repository;

  const GetTodos(this.repository);

  Future<List<TodoEntity>> call() async {
    return await repository.getTodos();
  }
}
