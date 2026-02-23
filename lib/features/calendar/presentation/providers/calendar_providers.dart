import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/usecases/get_events_for_month.dart';
import '../../domain/usecases/get_all_upcoming_events.dart';
import '../../data/fakes/fake_calendar_repository.dart';

// Repository provider - defaults to fake
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return FakeCalendarRepository();
});

// Use case providers
final getEventsForMonthProvider = Provider<GetEventsForMonth>((ref) {
  return GetEventsForMonth(ref.watch(calendarRepositoryProvider));
});

final getAllUpcomingEventsProvider = Provider<GetAllUpcomingEvents>((ref) {
  return GetAllUpcomingEvents(ref.watch(calendarRepositoryProvider));
});

// State: selected month (year, month)
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// State: selected day
final selectedDayProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Per-month cache — each month keeps its own loaded state.
// NOT autoDispose so data survives while user swipes between months.
final monthEventsFamilyProvider =
    FutureProvider.family<List<CalendarEventEntity>, DateTime>(
        (ref, month) async {
  final useCase = ref.watch(getEventsForMonthProvider);
  return await useCase(month.year, month.month);
});

// Convenience alias for the currently selected month
final monthEventsProvider =
    FutureProvider.autoDispose<List<CalendarEventEntity>>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  return ref.watch(monthEventsFamilyProvider(selectedMonth)).when(
        data: (e) => e,
        loading: () => const [],
        error: (_, __) => const [],
      );
});

// All upcoming events (for list view — multi-month continuous scroll)
final allUpcomingEventsProvider =
    FutureProvider.autoDispose<List<CalendarEventEntity>>((ref) async {
  final useCase = ref.watch(getAllUpcomingEventsProvider);
  return await useCase();
});

// Alias used by the list view tab — reads allUpcomingEventsProvider
final listViewEventsProvider =
    FutureProvider.autoDispose<List<CalendarEventEntity>>((ref) async {
  return ref.watch(allUpcomingEventsProvider).when(
        data: (e) => e,
        loading: () => const [],
        error: (_, __) => const [],
      );
});

// Events grouped by day for the selected month.
// Uses the family provider so cached data is NOT cleared while loading next month.
final eventsByDayProvider =
    Provider.autoDispose<Map<int, List<CalendarEventEntity>>>((ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final eventsAsync = ref.watch(monthEventsFamilyProvider(selectedMonth));
  return eventsAsync.maybeWhen(
    data: (events) {
      final Map<int, List<CalendarEventEntity>> grouped = {};
      for (final event in events) {
        if (event.date != null) {
          final day = event.date!.day;
          grouped.putIfAbsent(day, () => []).add(event);
        }
      }
      return grouped;
    },
    orElse: () => {},
  );
});

// Events for the selected day.
final selectedDayEventsProvider =
    Provider.autoDispose<List<CalendarEventEntity>>((ref) {
  final selectedDay = ref.watch(selectedDayProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final eventsAsync = ref.watch(monthEventsFamilyProvider(selectedMonth));
  return eventsAsync.maybeWhen(
    data: (events) {
      return events
          .where((e) =>
              e.date != null &&
              e.date!.year == selectedDay.year &&
              e.date!.month == selectedDay.month &&
              e.date!.day == selectedDay.day)
          .toList();
    },
    orElse: () => [],
  );
});
