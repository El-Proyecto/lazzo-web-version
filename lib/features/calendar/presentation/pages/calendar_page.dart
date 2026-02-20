import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_header.dart';
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

  String _getMonthTitle(DateTime month) {
    return '${_months[month.month - 1]} ${month.year}';
  }

  /// Calculate the number of weeks (rows) needed for a month
  int _weeksInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDay.weekday % 7; // 0=Sun
    return ((startingWeekday + daysInMonth) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final eventsByDay = ref.watch(eventsByDayProvider);
    final selectedDayEvents = ref.watch(selectedDayEventsProvider);
    final monthEventsAsync = ref.watch(monthEventsProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: const CommonAppBar(title: 'Calendar'),
      body: Column(
        children: [
          // Month title + view toggle
          CalendarHeader(
            title: _getMonthTitle(selectedMonth),
            viewMode: _viewMode,
            onViewModeChanged: (mode) {
              setState(() {
                _viewMode = mode;
              });
            },
          ),
          // Content area
          Expanded(
            child: _viewMode == CalendarViewMode.calendar
                ? _buildCalendarView(
                    selectedMonth,
                    selectedDay,
                    eventsByDay,
                    selectedDayEvents,
                    monthEventsAsync,
                  )
                : _buildListView(monthEventsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(
    DateTime selectedMonth,
    DateTime selectedDay,
    Map<int, List<dynamic>> eventsByDay,
    List<dynamic> selectedDayEvents,
    AsyncValue<List<dynamic>> monthEventsAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        // Calculate calendar grid height dynamically
        final weeks = _weeksInMonth(selectedMonth.year, selectedMonth.month);
        // weekday headers(~24) + gap(8) + rows(weeks * 56) + bottom padding(8)
        final calendarHeight = 24.0 + 8 + (weeks * 56.0) + 8;
        final calendarRatio = calendarHeight / totalHeight;
        final sheetInitial = (1.0 - calendarRatio).clamp(0.25, 0.75);

        return Stack(
          children: [
            // Calendar grid at the top
            Column(
              mainAxisSize: MainAxisSize.min,
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
                  loading: () => SizedBox(
                    height: calendarHeight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: BrandColors.planning,
                      ),
                    ),
                  ),
                  error: (error, _) => SizedBox(
                    height: calendarHeight,
                    child: const Center(
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
              initialChildSize: sheetInitial,
              minChildSize: sheetInitial,
              maxChildSize: 0.93,
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
      },
    );
  }

  Widget _buildListView(AsyncValue<List<dynamic>> monthEventsAsync) {
    return monthEventsAsync.when(
      data: (events) => CalendarListView(
        events: events.cast(),
        onSwipeLeft: _goToNextMonth,
        onSwipeRight: _goToPreviousMonth,
      ),
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
