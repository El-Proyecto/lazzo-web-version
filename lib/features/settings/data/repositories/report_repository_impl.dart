import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../data_sources/report_remote_data_source.dart';

/// Implementation of ReportRepository using Supabase
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _dataSource;

  ReportRepositoryImpl(this._dataSource);

  @override
  Future<void> submitReport(ReportEntity report) async {
    try {
      await _dataSource.submitReport(
        category: report.category,
        description: report.description,
      );
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }
}
