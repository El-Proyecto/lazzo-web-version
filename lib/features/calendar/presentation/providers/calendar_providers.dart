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

// Events for the currently selected month
final monthEventsProvider =
    FutureProvider.autoDispose<List<CalendarEventEntity>>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final useCase = ref.watch(getEventsForMonthProvider);
  return await useCase(selectedMonth.year, selectedMonth.month);
});

// All upcoming events (for list view)
final allUpcomingEventsProvider =
    FutureProvider.autoDispose<List<CalendarEventEntity>>((ref) async {
  final useCase = ref.watch(getAllUpcomingEventsProvider);
  return await useCase();
});

// Events grouped by day for the selected month
final eventsByDayProvider =
    Provider.autoDispose<Map<int, List<CalendarEventEntity>>>((ref) {
  final eventsAsync = ref.watch(monthEventsProvider);
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

// Events for the selected day
final selectedDayEventsProvider =
    Provider.autoDispose<List<CalendarEventEntity>>((ref) {
  final selectedDay = ref.watch(selectedDayProvider);
  final eventsAsync = ref.watch(monthEventsProvider);
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
