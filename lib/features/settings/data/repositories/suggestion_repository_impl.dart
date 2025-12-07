import '../../domain/entities/suggestion_entity.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../data_sources/suggestion_remote_data_source.dart';

/// Implementation of SuggestionRepository using Supabase
class SuggestionRepositoryImpl implements SuggestionRepository {
  final SuggestionRemoteDataSource _dataSource;

  SuggestionRepositoryImpl(this._dataSource);

  @override
  Future<void> submitSuggestion(SuggestionEntity suggestion) async {
    try {
      await _dataSource.submitSuggestion(
        description: suggestion.description,
      );
    } catch (e) {
      throw Exception('Failed to submit suggestion: $e');
    }
  }
}
