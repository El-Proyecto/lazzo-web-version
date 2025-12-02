import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';

/// Provider for the report repository
/// P1: Returns null (no implementation yet)
/// P2: Will be overridden in main.dart with Supabase implementation
final reportRepositoryProvider = Provider<ReportRepository?>((ref) => null);

/// State notifier for report submission
class ReportController extends StateNotifier<AsyncValue<void>> {
  final ReportRepository? repository;

  ReportController(this.repository) : super(const AsyncValue.data(null));

  /// Submit a problem report
  Future<void> submitReport({
    required String category,
    required String description,
    required String userId,
  }) async {
    print('\n🚀 [ReportController] Submitting report: category=$category');
    state = const AsyncValue.loading();

    try {
      if (repository == null) {
        // P1: Simulate success without actual submission (no delay)
        print('⚠️ [ReportController] Using fake repository (P1)');
        state = const AsyncValue.data(null);
        return;
      }

      final report = ReportEntity(
        category: category,
        description: description,
        userId: userId,
        createdAt: DateTime.now(),
      );

      await repository!.submitReport(report);
      state = const AsyncValue.data(null);
      print('✅ [ReportController] Report submitted successfully');
    } catch (e, st) {
      print('❌ [ReportController] Failed to submit report: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for the report controller
final reportControllerProvider =
    StateNotifierProvider<ReportController, AsyncValue<void>>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportController(repository);
});
