import '../entities/suggestion_entity.dart';

/// Repository interface for user suggestions
abstract class SuggestionRepository {
  /// Submit a new suggestion
  Future<void> submitSuggestion(SuggestionEntity suggestion);
}
