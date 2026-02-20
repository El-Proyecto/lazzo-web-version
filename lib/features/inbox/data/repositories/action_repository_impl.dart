import '../../domain/entities/action.dart';
import '../../domain/repositories/action_repository.dart';
import '../data_sources/action_remote_data_source.dart';

/// Real implementation that computes actions from live Supabase event data.
/// Actions are derived from event state — no dedicated actions table needed.
class ActionRepositoryImpl implements ActionRepository {
  final ActionRemoteDataSource _dataSource;

  /// Local dismissals (in-memory fallback when dismissed_actions table
  /// doesn't exist yet in beta).
  final Set<String> _localDismissals = {};

  ActionRepositoryImpl(this._dataSource);

  @override
  Future<List<ActionEntity>> getActions() async {
    final rows = await _dataSource.getHostActionData();
    final dismissed = await _dataSource.getDismissedActionKeys();

    final now = DateTime.now();
    final actions = <ActionEntity>[];

    for (final row in rows) {
      final undecidedCount = row.maybeCount + row.pendingCount;

      // An event is expired when its date has passed while still pending/confirmed.
      // Check end_datetime first; if null, fall back to start_datetime.
      // Expired events should only show rescheduleExpiredEvent — not reminder/confirm.
      final bool isExpired;
      if (row.endDatetime != null) {
        isExpired = row.endDatetime!.isBefore(now);
      } else if (row.startDatetime != null) {
        isExpired = row.startDatetime!.isBefore(now);
      } else {
        isExpired = false;
      }

      // --- remindMaybeVoters ---
      // When: event is pending/confirmed, NOT expired, AND has maybe/pending guests
      if (!isExpired &&
          (row.eventStatus == 'pending' || row.eventStatus == 'confirmed') &&
          undecidedCount > 0) {
        final key = 'remind_maybe_voters_${row.eventId}';
        if (!dismissed.contains(key) && !_localDismissals.contains(key)) {
          actions.add(ActionEntity(
            id: key,
            title: 'Remind maybe voters',
            subtitle:
                '$undecidedCount guest${undecidedCount == 1 ? '' : 's'} haven\'t responded yet',
            type: ActionType.remindMaybeVoters,
            status: ActionStatus.pending,
            priority: undecidedCount >= 3
                ? ActionPriority.high
                : ActionPriority.medium,
            createdAt: now,
            dueDate: row.startDatetime,
            eventId: row.eventId,
            eventName: row.eventName,
            eventEmoji: row.eventEmoji,
            contextInfo:
                '$undecidedCount guest${undecidedCount == 1 ? '' : 's'} haven\'t responded',
          ));
        }
      }

      // --- confirmEvent ---
      // When: event is pending, NOT expired, AND start_datetime is within 24 hours
      if (!isExpired &&
          row.eventStatus == 'pending' &&
          row.startDatetime != null) {
        final hoursUntilStart = row.startDatetime!.difference(now).inHours;
        if (hoursUntilStart >= 0 && hoursUntilStart <= 24) {
          final key = 'confirm_event_${row.eventId}';
          if (!dismissed.contains(key) && !_localDismissals.contains(key)) {
            actions.add(ActionEntity(
              id: key,
              title: 'Confirm event',
              subtitle: 'Event starts in less than 24h',
              type: ActionType.confirmEvent,
              status: ActionStatus.pending,
              priority: ActionPriority.urgent,
              createdAt: now,
              dueDate: row.startDatetime,
              eventId: row.eventId,
              eventName: row.eventName,
              eventEmoji: row.eventEmoji,
              contextInfo: 'Starts soon — confirm now',
            ));
          }
        }
      }

      // --- rescheduleExpiredEvent ---
      // When: event is expired (date passed) and still pending/confirmed
      if (isExpired &&
          (row.eventStatus == 'pending' || row.eventStatus == 'confirmed')) {
        final key = 'reschedule_expired_event_${row.eventId}';
        if (!dismissed.contains(key) && !_localDismissals.contains(key)) {
          actions.add(ActionEntity(
            id: key,
            title: 'Reschedule event',
            subtitle: 'Event has expired — set new dates',
            type: ActionType.rescheduleExpiredEvent,
            status: ActionStatus.pending,
            priority: ActionPriority.medium,
            createdAt: now,
            eventId: row.eventId,
            eventName: row.eventName,
            eventEmoji: row.eventEmoji,
            contextInfo: 'Event has expired — set new dates',
          ));
        }
      }

      // --- reviewGuests ---
      // When: confirmed AND start within 3 days AND has maybe/pending guests
      if (row.eventStatus == 'confirmed' &&
          row.startDatetime != null &&
          undecidedCount > 0) {
        final daysUntilStart = row.startDatetime!.difference(now).inDays;
        if (daysUntilStart >= 0 && daysUntilStart <= 3) {
          final key = 'review_guests_${row.eventId}';
          if (!dismissed.contains(key) && !_localDismissals.contains(key)) {
            actions.add(ActionEntity(
              id: key,
              title: 'Review guest list',
              subtitle:
                  '$undecidedCount guest${undecidedCount == 1 ? '' : 's'} still maybe',
              type: ActionType.reviewGuests,
              status: ActionStatus.pending,
              priority: ActionPriority.medium,
              createdAt: now,
              dueDate: row.startDatetime,
              eventId: row.eventId,
              eventName: row.eventName,
              eventEmoji: row.eventEmoji,
              contextInfo:
                  '$undecidedCount guest${undecidedCount == 1 ? '' : 's'} are still maybe',
            ));
          }
        }
      }

      // --- addPhotos ---
      // When: event is living AND host has 0 photos
      if (row.eventStatus == 'living' && row.hostPhotoCount == 0) {
        final key = 'add_photos_${row.eventId}';
        if (!dismissed.contains(key) && !_localDismissals.contains(key)) {
          actions.add(ActionEntity(
            id: key,
            title: 'Add photos',
            subtitle: 'You haven\'t added any photos yet',
            type: ActionType.addPhotos,
            status: ActionStatus.pending,
            priority: ActionPriority.high,
            createdAt: now,
            dueDate: row.endDatetime,
            eventId: row.eventId,
            eventName: row.eventName,
            eventEmoji: row.eventEmoji,
            contextInfo: 'You haven\'t added any photos yet',
          ));
        }
      }
    }

    // Sort: urgent first, then high, then by due date
    actions.sort((a, b) {
      final priorityOrder = b.priority.index.compareTo(a.priority.index);
      if (priorityOrder != 0) return priorityOrder;
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return actions;
  }

  @override
  Future<void> dismissAction(String actionId) async {
    // Parse the composite key: type_eventId
    final parts = actionId.split('_');
    if (parts.length >= 3) {
      // Key format: "action_type_eventId" — type may contain underscores
      final eventId = parts.last;
      final actionType = parts.sublist(0, parts.length - 1).join('_');
      await _dataSource.dismissAction(
        actionType: actionType,
        eventId: eventId,
      );
    }
    // Always add to local dismissals as fallback
    _localDismissals.add(actionId);
  }

  @override
  Future<int> getPendingCount() async {
    final actions = await getActions();
    return actions.length;
  }
}
