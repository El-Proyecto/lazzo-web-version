import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/skeletons/calendar_list_skeleton.dart';
import '../../../../shared/themes/colors.dart';
import '../../../home/presentation/providers/home_event_providers.dart';
import '../../../home/domain/entities/home_event.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_header.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/calendar_list_view.dart';
import '../widgets/day_events_bottom_sheet.dart';
import '../../../../services/analytics_service.dart';

/// Main Calendar page with two views: Calendar (grid) and List
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarViewMode _viewMode = CalendarViewMode.calendar;

  late final PageController _pageController;
  late final DateTime _appLaunchMonth; // page _kCenterPage = this month
  bool _isAnimatingToPage = false;

  static const _kCenterPage = 600;

  // Fixed max calendar height: weekday header + 6 rows + padding = 376px
  static const double _calendarHeight = 24.0 + 8.0 + (6 * 56.0) + 8.0;

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
    _appLaunchMonth = DateTime(now.year, now.month);
    _pageController = PageController(initialPage: _kCenterPage);
    // Prefetch adjacent months immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAdjacentMonths(_kCenterPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageForMonth(DateTime month) {
    final diff = (month.year - _appLaunchMonth.year) * 12 +
        (month.month - _appLaunchMonth.month);
    return _kCenterPage + diff;
  }

  DateTime _monthForPage(int page) => DateTime(
        _appLaunchMonth.year,
        _appLaunchMonth.month + (page - _kCenterPage),
      );

  String _getMonthTitle(DateTime month) =>
      '${_months[month.month - 1]} ${month.year}';

  /// Returns the toggle color matching the nav bar main button color
  Color _getToggleColor(WidgetRef ref) {
    final nextEventStatus = ref.watch(navBarStateProvider);
    if (nextEventStatus == HomeEventStatus.living) {
      return BrandColors.living;
    } else if (nextEventStatus == HomeEventStatus.recap) {
      return BrandColors.recap;
    }
    return BrandColors.planning;
  }

  /// Preload the months before and after [currentPage] so swiping never
  /// triggers a loading spinner.
  void _preloadAdjacentMonths(int currentPage) {
    for (final offset in [-1, 1, 2]) {
      final month = _monthForPage(currentPage + offset);
      ref.read(monthEventsFamilyProvider(month));
    }
  }

  /// After landing on a new month, auto-select:
  ///   1. Today — if it's the current calendar month
  ///   2. First event day in that month (from cached data)
  ///   3. Day 1 of the month
  void _autoSelectDay(DateTime month) {
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month) {
      ref.read(selectedDayProvider.notifier).state =
          DateTime(now.year, now.month, now.day);
      return;
    }
    final cached = ref.read(monthEventsFamilyProvider(month)).valueOrNull;
    if (cached != null && cached.isNotEmpty) {
      final days = cached
          .where((e) => e.date != null)
          .map((e) => DateTime(e.date!.year, e.date!.month, e.date!.day))
          .toList()
        ..sort();
      if (days.isNotEmpty) {
        ref.read(selectedDayProvider.notifier).state = days.first;
        return;
      }
    }
    ref.read(selectedDayProvider.notifier).state =
        DateTime(month.year, month.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    // Sync PageView when selectedMonthProvider changes externally (arrow taps,
    // list-view scroll sync, etc.)
    ref.listen<DateTime>(selectedMonthProvider, (prev, next) {
      if (_isAnimatingToPage) return;
      final targetPage = _pageForMonth(next);
      final currentPage = _pageController.page?.round() ?? _kCenterPage;
      if (targetPage == currentPage) return;
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
    });

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: const CommonAppBar(title: 'Calendar'),
      body: Column(
        children: [
          CalendarHeader(
            title: _getMonthTitle(selectedMonth),
            viewMode: _viewMode,
            onViewModeChanged: (mode) {
              setState(() => _viewMode = mode);
              AnalyticsService.screenViewed('calendar');
            },
            activeColor: _getToggleColor(ref),
          ),
          Expanded(
            child: _viewMode == CalendarViewMode.calendar
                ? _buildCalendarView(selectedMonth, selectedDay)
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(DateTime selectedMonth, DateTime selectedDay) {
    final selectedDayEvents = ref.watch(selectedDayEventsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final calendarRatio = _calendarHeight / constraints.maxHeight;
        final sheetInitial = (1.1 - calendarRatio).clamp(0.25, 0.75);

        return Stack(
          children: [
            // Always-visible PageView — each page loads its own data internally
            SizedBox(
              height: _calendarHeight,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  if (_isAnimatingToPage) return;
                  final newMonth = _monthForPage(page);
                  ref.read(selectedMonthProvider.notifier).state = newMonth;
                  _autoSelectDay(newMonth);
                  _preloadAdjacentMonths(page);
                },
                itemBuilder: (context, page) {
                  final month = _monthForPage(page);
                  return _CalendarGridPage(
                    month: month,
                    selectedDate: selectedDay,
                    onDaySelected: (date) {
                      ref.read(selectedDayProvider.notifier).state = date;
                      AnalyticsService.screenViewed('calendar');
                    },
                  );
                },
              ),
            ),
            // Bottom sheet for the selected day's events
            DraggableScrollableSheet(
              initialChildSize: sheetInitial,
              minChildSize: sheetInitial,
              maxChildSize: 0.93,
              builder: (context, scrollController) => DayEventsBottomSheet(
                selectedDate: selectedDay,
                events: selectedDayEvents.cast(),
                scrollController: scrollController,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListView() {
    final listEventsAsync = ref.watch(allUpcomingEventsProvider);
    return listEventsAsync.when(
      data: (events) => CalendarListView(events: events),
      loading: () => const CalendarListSkeleton(),
      error: (_, __) => const Center(
        child: Text(
          'Failed to load events',
          style: TextStyle(color: BrandColors.text2),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-page grid widget — owns its own data loading without blocking the PageView
// ---------------------------------------------------------------------------

class _CalendarGridPage extends ConsumerWidget {
  final DateTime month;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarGridPage({
    required this.month,
    required this.selectedDate,
    required this.onDaySelected,
  });

  Map<int, List<CalendarEventEntity>> _buildEventsByDay(
    List<CalendarEventEntity> events,
  ) {
    final Map<int, List<CalendarEventEntity>> grouped = {};
    for (final event in events) {
      if (event.date != null &&
          event.date!.year == month.year &&
          event.date!.month == month.month) {
        grouped.putIfAbsent(event.date!.day, () => []).add(event);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(monthEventsFamilyProvider(month));
    final Map<int, List<CalendarEventEntity>> eventsByDay =
        eventsAsync.maybeWhen(
      data: _buildEventsByDay,
      orElse: () => const <int, List<CalendarEventEntity>>{},
    );

    return Stack(
      children: [
        CalendarGrid(
          key: ValueKey('${month.year}-${month.month}'),
          year: month.year,
          month: month.month,
          selectedDate: selectedDate,
          eventsByDay: eventsByDay,
          onDaySelected: onDaySelected,
        ),
        // Subtle corner spinner while loading — grid stays fully visible
        if (eventsAsync.isLoading)
          Positioned(
            top: 4,
            right: 8,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: BrandColors.text2.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}
