import '../entities/suggestion.dart';
import '../repositories/suggestion_repository.dart';

/// Use case to get all suggestions for an event
class GetEventSuggestions {
  final SuggestionRepository repository;

  const GetEventSuggestions(this.repository);

  Future<List<Suggestion>> call(String eventId) async {
    return await repository.getEventSuggestions(eventId);
  }
}
