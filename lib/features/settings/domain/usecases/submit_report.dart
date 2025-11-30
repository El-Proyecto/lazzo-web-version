import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

/// Use case for submitting a problem report
class SubmitReport {
  final ReportRepository repository;

  SubmitReport(this.repository);

  Future<void> call(ReportEntity report) {
    return repository.submitReport(report);
  }
}
