import '../repositories/memory_repository.dart';

/// Use case for closing recap phase early
///
/// Requirements:
/// - Host only
/// - If photos exist and no cover is set, first photo becomes cover automatically
/// - Status changes from 'recap' to 'ended'
class CloseRecap {
  final MemoryRepository _repository;

  CloseRecap(this._repository);

  /// Close recap phase for an event
  /// Returns true if successful
  Future<bool> call(String eventId) async {
    return _repository.closeRecap(eventId);
  }
}
