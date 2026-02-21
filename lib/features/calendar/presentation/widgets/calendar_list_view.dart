import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/cards/event_small_card.dart';
import '../../../../shared/components/cards/memory_small_card.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/calendar_event_entity.dart';
import '../providers/calendar_providers.dart';

// ---------------------------------------------------------------------------
// Row model — flat list of visual items
// ---------------------------------------------------------------------------

enum _RowKind { monthHeader, dayHeader, dayGap, eventCard }

class _Row {
  final _RowKind kind;
  final DateTime? month; // for monthHeader
  final DateTime? day; // for dayHeader
  final CalendarEventEntity? event; // for eventCard
  const _Row({required this.kind, this.month, this.day, this.event});
}

// Estimated row heights used to compute section offsets
const double _kMonthHeaderH = 46.0; // text + bottom padding
const double _kDayHeaderH = 28.0; // text + bottom padding
const double _kDayGapH = Gaps.lg; // vertical gap between day groups
const double _kCardH = 90.0; // card widget height including bottom gap
const double _kListPaddingV = Gaps.md; // ListView vertical padding

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Multi-month continuous scroll list — synced bidirectionally with
/// [selectedMonthProvider] so Calendar ↔ List views stay in step.
class CalendarListView extends ConsumerStatefulWidget {
  final List<CalendarEventEntity> events;

  const CalendarListView({
    super.key,
    required this.events,
  });

  @override
  ConsumerState<CalendarListView> createState() => _CalendarListViewState();
}

class _CalendarListViewState extends ConsumerState<CalendarListView> {
  late final ScrollController _scrollController;

  // Flat row list built from events
  List<_Row> _rows = [];

  // month DateTime → estimated pixel offset (top of that month's header)
  Map<DateTime, double> _monthOffset = {};

  // Sorted list of sections (months that have at least one event)
  List<DateTime> _sectionMonths = [];

  // Guards against feedback loops between scroll listener and provider listener
  bool _programmaticScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _buildRowData();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // After first frame, jump to the month that the calendar is showing
      _scrollToMonth(ref.read(selectedMonthProvider), animated: false);
    });
  }

  @override
  void didUpdateWidget(CalendarListView old) {
    super.didUpdateWidget(old);
    if (widget.events != old.events) {
      _buildRowData();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data building
  // ---------------------------------------------------------------------------

  /// Build flat [_rows], [_monthOffset], [_sectionMonths].
  void _buildRowData() {
    // Group: month → day → events
    final Map<DateTime, Map<DateTime, List<CalendarEventEntity>>> byMonth = {};
    for (final event in widget.events) {
      if (event.date == null) continue;
      final m = DateTime(event.date!.year, event.date!.month);
      final d = DateTime(event.date!.year, event.date!.month, event.date!.day);
      byMonth.putIfAbsent(m, () => {}).putIfAbsent(d, () => []).add(event);
    }

    final sortedMonths = byMonth.keys.toList()..sort();
    final rows = <_Row>[];
    final monthOffset = <DateTime, double>{};
    double offsetAccum = _kListPaddingV;

    for (final month in sortedMonths) {
      monthOffset[month] = offsetAccum;
      rows.add(_Row(kind: _RowKind.monthHeader, month: month));
      offsetAccum += _kMonthHeaderH;

      final sortedDays = byMonth[month]!.keys.toList()..sort();
      for (int di = 0; di < sortedDays.length; di++) {
        if (di > 0) {
          rows.add(const _Row(kind: _RowKind.dayGap));
          offsetAccum += _kDayGapH;
        }
        final day = sortedDays[di];
        rows.add(_Row(kind: _RowKind.dayHeader, day: day));
        offsetAccum += _kDayHeaderH;

        for (final event in byMonth[month]![day]!) {
          rows.add(_Row(kind: _RowKind.eventCard, event: event));
          offsetAccum += _kCardH;
        }
      }
    }

    _rows = rows;
    _monthOffset = {...monthOffset};
    _sectionMonths = sortedMonths;
  }

  // ---------------------------------------------------------------------------
  // Scroll ↔ Provider sync
  // ---------------------------------------------------------------------------

  /// Called every scroll frame. Determines which month header is at/above the
  /// top of the viewport and updates [selectedMonthProvider].
  void _onScroll() {
    if (_programmaticScrolling) return;
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;

    // Find the last month whose estimated offset is ≤ current scroll position
    DateTime? current;
    for (final month in _sectionMonths) {
      final mo = _monthOffset[month] ?? 0.0;
      if (mo <= offset + 1.0) {
        current = month;
      } else {
        break;
      }
    }
    if (current == null && _sectionMonths.isNotEmpty) {
      current = _sectionMonths.first;
    }
    if (current == null) return;

    final providerMonth = ref.read(selectedMonthProvider);
    if (current != providerMonth) {
      ref.read(selectedMonthProvider.notifier).state = current;
    }
  }

  /// Scroll the list to [month]'s section. Uses estimated offsets.
  void _scrollToMonth(DateTime month, {bool animated = true}) {
    if (!_scrollController.hasClients) return;

    // Find the closest section month (in case the exact month has no events)
    DateTime? target;
    for (final m in _sectionMonths) {
      if (!m.isBefore(month) && target == null) target = m;
    }
    target ??= _sectionMonths.isEmpty ? null : _sectionMonths.last;
    if (target == null) return;

    final offset = (_monthOffset[target] ?? 0.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _programmaticScrolling = true;

    if (animated) {
      _scrollController
          .animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) => _programmaticScrolling = false);
    } else {
      _scrollController.jumpTo(offset);
      _programmaticScrolling = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  String _getMonthTitle(DateTime month) {
    const months = [
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
    return '${months[month.month - 1]} ${month.year}';
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    if (dateOnly == today) return 'Today — $weekday, ${date.day} $month';
    if (dateOnly == tomorrow) return 'Tomorrow — $weekday, ${date.day} $month';
    return '$weekday, ${date.day} $month';
  }

  String _formatEventDateTime(CalendarEventEntity event) {
    if (event.date == null) return 'Date TBD';
    final start = event.date!;
    final end = event.endDate;

    String fmtTime(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    String fmtTimeH(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';

    if (end == null) return fmtTime(start);

    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (sameDay) return '${fmtTime(start)}-${fmtTimeH(end)}';

    const monthsShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${fmtTime(start)} - ${end.day} ${monthsShort[end.month - 1]} ${fmtTimeH(end)}';
  }

  String _formatMemoryDate(CalendarEventEntity event) {
    if (event.date == null) return '';
    const monthsShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${event.date!.day} ${monthsShort[event.date!.month - 1]}';
  }

  EventSmallCardState _mapStatus(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.pending:
        return EventSmallCardState.pending;
      case CalendarEventStatus.confirmed:
        return EventSmallCardState.confirmed;
      case CalendarEventStatus.living:
        return EventSmallCardState.living;
      case CalendarEventStatus.recap:
        return EventSmallCardState.recap;
      case CalendarEventStatus.ended:
        return EventSmallCardState.pending;
    }
  }

  bool _isMemoryEvent(CalendarEventEntity event) =>
      event.status == CalendarEventStatus.ended && event.hasMemory;

  // ---------------------------------------------------------------------------
  // Item builders
  // ---------------------------------------------------------------------------

  Widget _buildMonthHeader(DateTime month) {
    return Padding(
      padding: const EdgeInsets.only(top: Gaps.xs, bottom: Gaps.md),
      child: Text(
        _getMonthTitle(month),
        style: AppText.titleLargeEmph.copyWith(color: BrandColors.text1),
      ),
    );
  }

  Widget _buildDayHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: Text(
        _formatDayHeader(date),
        style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
      ),
    );
  }

  Widget _buildEventCard(CalendarEventEntity event) {
    if (_isMemoryEvent(event)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Gaps.xs),
        child: MemorySmallCard(
          title: event.name,
          dateTime: _formatMemoryDate(event),
          location: event.location,
          coverPhotoUrl: event.coverPhotoUrl,
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.memory,
            arguments: {'memoryId': event.id},
          ),
        ),
      );
    }

    final isLivingOrRecap = event.status == CalendarEventStatus.living ||
        event.status == CalendarEventStatus.recap;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.xs),
      child: EventSmallCard(
        emoji: event.emoji,
        title: event.name,
        dateTime: _formatEventDateTime(event),
        location: event.location,
        state: _mapStatus(event.status),
        isExpired: event.isPast && event.status == CalendarEventStatus.pending,
        onTap: () => Navigator.pushNamed(
          context,
          isLivingOrRecap ? AppRouter.eventLiving : AppRouter.event,
          arguments: {'eventId': event.id},
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // When the calendar view changes month (arrow tap / swipe), scroll here too
    ref.listen<DateTime>(selectedMonthProvider, (prev, next) {
      if (!_programmaticScrolling) {
        _scrollToMonth(next);
      }
    });

    if (widget.events.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionH,
        vertical: _kListPaddingV,
      ),
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final row = _rows[index];
        switch (row.kind) {
          case _RowKind.monthHeader:
            return _buildMonthHeader(row.month!);
          case _RowKind.dayHeader:
            return _buildDayHeader(row.day!);
          case _RowKind.dayGap:
            return const SizedBox(height: _kDayGapH);
          case _RowKind.eventCard:
            return _buildEventCard(row.event!);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note_outlined,
              size: 48, color: BrandColors.text2),
          const SizedBox(height: Gaps.sm),
          Text(
            'No upcoming events',
            style: AppText.bodyLarge.copyWith(color: BrandColors.text2),
          ),
          const SizedBox(height: Gaps.md),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRouter.createEvent),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.ctlH,
                vertical: Pads.ctlVXs,
              ),
              decoration: BoxDecoration(
                color: BrandColors.planning,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                'Create Event',
                style: AppText.labelLargeEmph.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
