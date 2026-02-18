import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/calendar_app_bar.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/calendar_list_view.dart';
import '../widgets/day_events_bottom_sheet.dart';

/// Main Calendar page with two views: Calendar (grid) and List
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarViewMode _viewMode = CalendarViewMode.calendar;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  void _goToNextMonth() {
    final current = ref.read(selectedMonthProvider);
    final next = DateTime(current.year, current.month + 1);
    ref.read(selectedMonthProvider.notifier).state = next;
  }

  void _goToPreviousMonth() {
    final current = ref.read(selectedMonthProvider);
    final prev = DateTime(current.year, current.month - 1);
    ref.read(selectedMonthProvider.notifier).state = prev;
  }

  void _onDaySelected(DateTime date) {
    ref.read(selectedDayProvider.notifier).state = date;
  }

  String _getTitle(DateTime month) {
    return '${_months[month.month - 1]} ${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final eventsByDay = ref.watch(eventsByDayProvider);
    final selectedDayEvents = ref.watch(selectedDayEventsProvider);
    final allEventsAsync = ref.watch(allUpcomingEventsProvider);
    final monthEventsAsync = ref.watch(monthEventsProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CalendarAppBar(
        title: _getTitle(selectedMonth),
        viewMode: _viewMode,
        onViewModeChanged: (mode) {
          setState(() {
            _viewMode = mode;
          });
        },
      ),
      body: _viewMode == CalendarViewMode.calendar
          ? _buildCalendarView(
              selectedMonth,
              selectedDay,
              eventsByDay,
              selectedDayEvents,
              monthEventsAsync,
            )
          : _buildListView(allEventsAsync),
    );
  }

  Widget _buildCalendarView(
    DateTime selectedMonth,
    DateTime selectedDay,
    Map<int, List<dynamic>> eventsByDay,
    List<dynamic> selectedDayEvents,
    AsyncValue<List<dynamic>> monthEventsAsync,
  ) {
    return Stack(
      children: [
        // Calendar grid at the top
        Column(
          children: [
            monthEventsAsync.when(
              data: (_) => CalendarGrid(
                year: selectedMonth.year,
                month: selectedMonth.month,
                selectedDate: selectedDay,
                eventsByDay: eventsByDay.cast(),
                onDaySelected: _onDaySelected,
                onSwipeLeft: _goToNextMonth,
                onSwipeRight: _goToPreviousMonth,
              ),
              loading: () => const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.planning,
                  ),
                ),
              ),
              error: (error, _) => const SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'Failed to load events',
                    style: TextStyle(color: BrandColors.text2),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Bottom sheet for selected day events
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return DayEventsBottomSheet(
              selectedDate: selectedDay,
              events: selectedDayEvents.cast(),
              scrollController: scrollController,
            );
          },
        ),
      ],
    );
  }

  Widget _buildListView(AsyncValue<List<dynamic>> allEventsAsync) {
    return allEventsAsync.when(
      data: (events) => CalendarListView(events: events.cast()),
      loading: () => const Center(
        child: CircularProgressIndicator(color: BrandColors.planning),
      ),
      error: (error, _) => const Center(
        child: Text(
          'Failed to load events',
          style: TextStyle(color: BrandColors.text2),
        ),
      ),
    );
  }
}
