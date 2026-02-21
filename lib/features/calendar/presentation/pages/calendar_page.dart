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

  // PageView state for the calendar grid
  late final PageController _pageController;
  late final DateTime _baseMonth; // page 600 = this month
  bool _isAnimatingToPage = false;

  static const _kCenterPage = 600;

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _pageController = PageController(initialPage: _kCenterPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Convert a month DateTime to its PageView page index
  int _pageForMonth(DateTime month) {
    final diff =
        (month.year - _baseMonth.year) * 12 + (month.month - _baseMonth.month);
    return _kCenterPage + diff;
  }

  // Convert a PageView page index to a month DateTime
  DateTime _monthForPage(int page) {
    return DateTime(_baseMonth.year, _baseMonth.month + (page - _kCenterPage));
  }

  void _onDaySelected(DateTime date) {
    ref.read(selectedDayProvider.notifier).state = date;
  }

  String _getMonthTitle(DateTime month) {
    return '${_months[month.month - 1]} ${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final eventsByDay = ref.watch(eventsByDayProvider);
    final selectedDayEvents = ref.watch(selectedDayEventsProvider);
    // Use family provider so each month has its own cached async state
    final monthEventsAsync =
        ref.watch(monthEventsFamilyProvider(selectedMonth));

    // Sync PageView when selectedMonthProvider changes externally (e.g. arrow taps)
    ref.listen<DateTime>(selectedMonthProvider, (prev, next) {
      if (_isAnimatingToPage) return;
      final targetPage = _pageForMonth(next);
      final currentPage = _pageController.page?.round() ?? _kCenterPage;
      if (targetPage != currentPage) {
        _isAnimatingToPage = true;
        _pageController
            .animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
            .then((_) {
          if (mounted) _isAnimatingToPage = false;
        });
      }
    });

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
                : _buildListView(),
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
    // Always allocate max possible height (6 rows) so adjacent PageView pages
    // with more rows never overflow. The layout is identical for 4/5/6-row months.
    const double calendarHeight = 24.0 + 8.0 + (6 * 56.0) + 8.0; // 376px

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final calendarRatio = calendarHeight / totalHeight;
        final sheetInitial = (1.1 - calendarRatio).clamp(0.25, 0.75);

        return Stack(
          children: [
            // PageView-based calendar grid (real horizontal drag)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                monthEventsAsync.when(
                  data: (_) => SizedBox(
                    height: calendarHeight,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) {
                        if (_isAnimatingToPage) return;
                        final newMonth = _monthForPage(page);
                        ref.read(selectedMonthProvider.notifier).state =
                            newMonth;
                      },
                      itemBuilder: (context, page) {
                        final month = _monthForPage(page);
                        final isCurrentMonth =
                            month.year == selectedMonth.year &&
                                month.month == selectedMonth.month;
                        return CalendarGrid(
                          key: ValueKey('${month.year}-${month.month}'),
                          year: month.year,
                          month: month.month,
                          selectedDate: selectedDay,
                          // Only pass event dots for the current month;
                          // adjacent pages are empty while loading.
                          eventsByDay:
                              isCurrentMonth ? eventsByDay.cast() : const {},
                          onDaySelected: _onDaySelected,
                          // No swipe callbacks — PageView handles drag
                        );
                      },
                    ),
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

  Widget _buildListView() {
    final listEventsAsync = ref.watch(listViewEventsProvider);
    return listEventsAsync.when(
      data: (events) => CalendarListView(events: events),
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
