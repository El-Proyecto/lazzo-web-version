import '../entities/suggestion.dart';
import '../repositories/suggestion_repository.dart';

/// Use case to create a new suggestion
class CreateSuggestion {
  final SuggestionRepository repository;

  const CreateSuggestion(this.repository);

  Future<Suggestion> call({
    required String eventId,
    required String userId,
    required DateTime startDateTime,
    DateTime? endDateTime,
  }) async {
    return await repository.createSuggestion(
      eventId: eventId,
      userId: userId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );
  }
}
