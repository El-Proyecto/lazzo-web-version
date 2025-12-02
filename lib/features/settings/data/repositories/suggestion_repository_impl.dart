import '../../domain/entities/suggestion_entity.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../data_sources/suggestion_remote_data_source.dart';
import '../models/suggestion_model.dart';

/// Implementation of SuggestionRepository using Supabase
class SuggestionRepositoryImpl implements SuggestionRepository {
  final SuggestionRemoteDataSource _dataSource;

  SuggestionRepositoryImpl(this._dataSource);

  @override
  Future<void> submitSuggestion(SuggestionEntity suggestion) async {
    try {
      print('📦 [SuggestionRepository] Submitting suggestion...');

      final json = await _dataSource.submitSuggestion(
        description: suggestion.description,
      );

      final model = SuggestionModel.fromJson(json);
      print(
          '✅ [SuggestionRepository] Suggestion submitted successfully: id=${model.id}');
    } catch (e) {
      print('❌ [SuggestionRepository] Failed to submit suggestion: $e');
      throw Exception('Failed to submit suggestion: $e');
    }
  }
}
