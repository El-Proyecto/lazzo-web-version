import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../data_sources/report_remote_data_source.dart';
import '../models/report_model.dart';

/// Implementation of ReportRepository using Supabase
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _dataSource;

  ReportRepositoryImpl(this._dataSource);

  @override
  Future<void> submitReport(ReportEntity report) async {
    try {
      print('📦 [ReportRepository] Submitting report...');

      final json = await _dataSource.submitReport(
        category: report.category,
        description: report.description,
      );

      final model = ReportModel.fromJson(json);
      print(
          '✅ [ReportRepository] Report submitted successfully: id=${model.id}');
    } catch (e) {
      print('❌ [ReportRepository] Failed to submit report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }
}
