import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/realtime_service.dart';
import '../../features/home/presentation/providers/home_event_providers.dart';
import '../../features/event/presentation/providers/event_providers.dart';

/// Provider that watches Supabase Realtime RSVP changes and
/// invalidates the relevant Riverpod providers so the UI auto-refreshes.
///
/// Usage: `ref.listen(realtimeRefreshProvider, (_, __) {});`
/// in any ConsumerWidget that should react to live changes.
final realtimeRefreshProvider = Provider<void>((ref) {
  StreamSubscription<RealtimeChangeEvent>? rsvpSub;
  StreamSubscription<RealtimeChangeEvent>? eventSub;

  // Debounce: avoid spamming invalidations for rapid-fire changes
  Timer? debounce;

  void invalidateHome() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidate(nextEventControllerProvider);
      ref.invalidate(confirmedEventsControllerProvider);
      ref.invalidate(homeEventsControllerProvider);
      ref.invalidate(livingAndRecapEventsControllerProvider);
    });
  }

  try {
    final service = ref.watch(realtimeServiceProvider);

    rsvpSub = service.rsvpChanges.listen((change) {
      final eventId = change.eventId;

      // Invalidate event-specific providers
      if (eventId != null) {
        ref.invalidate(eventRsvpsProvider(eventId));
        ref.invalidate(userRsvpProvider(eventId));
        ref.invalidate(eventDetailProvider(eventId));
      }

      // Invalidate home providers (debounced)
      invalidateHome();
    });

    eventSub = service.eventChanges.listen((change) {
      final eventId = change.eventId;

      if (eventId != null) {
        ref.invalidate(eventDetailProvider(eventId));
      }

      invalidateHome();
    });
  } catch (_) {
    // Realtime not available — graceful degradation
  }

  ref.onDispose(() {
    debounce?.cancel();
    rsvpSub?.cancel();
    eventSub?.cancel();
  });
});
