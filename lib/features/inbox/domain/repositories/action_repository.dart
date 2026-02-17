import '../entities/action.dart';

/// Repository for host-facing actions.
/// Actions are computed from event state — no dedicated DB table needed for beta.
abstract class ActionRepository {
  /// Get all pending actions for the current user (as host).
  /// Returns actions sorted by priority/urgency.
  Future<List<ActionEntity>> getActions();

  /// Dismiss an action (user chose to ignore it).
  Future<void> dismissAction(String actionId);

  /// Get count of pending actions (for badge).
  Future<int> getPendingCount();
}
