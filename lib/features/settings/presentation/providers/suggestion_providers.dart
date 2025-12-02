import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/suggestion_entity.dart';
import '../../domain/repositories/suggestion_repository.dart';

/// Provider for the suggestion repository
/// P1: Returns null (no implementation yet)
/// P2: Will be overridden in main.dart with Supabase implementation
final suggestionRepositoryProvider =
    Provider<SuggestionRepository?>((ref) => null);

/// State notifier for suggestion submission
class SuggestionController extends StateNotifier<AsyncValue<void>> {
  final SuggestionRepository? repository;

  SuggestionController(this.repository) : super(const AsyncValue.data(null));

  /// Submit a suggestion
  Future<void> submitSuggestion({
    required String description,
    required String userId,
  }) async {
    print('\n🚀 [SuggestionController] Submitting suggestion');
    state = const AsyncValue.loading();

    try {
      if (repository == null) {
        // P1: Simulate success without actual submission
        print('⚠️ [SuggestionController] Using fake repository (P1)');
        state = const AsyncValue.data(null);
        return;
      }

      final suggestion = SuggestionEntity(
        description: description,
        userId: userId,
        createdAt: DateTime.now(),
      );

      await repository!.submitSuggestion(suggestion);
      state = const AsyncValue.data(null);
      print('✅ [SuggestionController] Suggestion submitted successfully');
    } catch (e, st) {
      print('❌ [SuggestionController] Failed to submit suggestion: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for the suggestion controller
final suggestionControllerProvider =
    StateNotifierProvider<SuggestionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(suggestionRepositoryProvider);
  return SuggestionController(repository);
});
