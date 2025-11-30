import '../entities/report_entity.dart';

/// Repository interface for problem reports
abstract class ReportRepository {
  /// Submit a new problem report
  Future<void> submitReport(ReportEntity report);
}
