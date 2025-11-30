import '../entities/suggestion_entity.dart';
import '../repositories/suggestion_repository.dart';

/// Use case for submitting a suggestion
class SubmitSuggestion {
  final SuggestionRepository repository;

  SubmitSuggestion(this.repository);

  Future<void> call(SuggestionEntity suggestion) {
    return repository.submitSuggestion(suggestion);
  }
}
