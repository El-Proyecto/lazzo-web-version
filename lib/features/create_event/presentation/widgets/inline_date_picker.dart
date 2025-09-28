import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Picker inline compacto de data estilo calendário
/// Mostra os dias do mês atual em formato compacto
class InlineDatePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateChanged;

  const InlineDatePicker({super.key, this.selectedDate, this.onDateChanged});

  @override
  State<InlineDatePicker> createState() => _InlineDatePickerState();
}

class _InlineDatePickerState extends State<InlineDatePicker> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _currentMonth = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Pads.ctlH),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.smAlt),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header do mês
          _buildMonthHeader(),
          const SizedBox(height: Gaps.sm),

          // Dias da semana
          _buildWeekdayHeaders(),
          const SizedBox(height: Gaps.xs),

          // Calendário
          _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _previousMonth,
          child: const Icon(Icons.chevron_left, color: BrandColors.text2, size: 20),
        ),
        Text(
          _formatMonth(_currentMonth),
          style: AppText.labelLarge.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: _nextMonth,
          child: const Icon(Icons.chevron_right, color: BrandColors.text2, size: 20),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekdays
          .map(
            (day) => SizedBox(
              width: 32,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];

    // Empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 32, height: 32));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isToday = _isToday(date);
      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () => _selectDate(date),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? BrandColors.planning
                  : isToday
                  ? BrandColors.bg2
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isToday && !isSelected
                  ? Border.all(
                      color: BrandColors.planning.withOpacity(0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: AppText.bodyMedium.copyWith(
                  color: isPast
                      ? BrandColors.text2.withOpacity(0.5)
                      : isSelected
                      ? BrandColors.text1
                      : BrandColors.text1,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Organize into rows
    List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final rowWidgets = dayWidgets.sublist(
        i,
        i + 7 > dayWidgets.length ? dayWidgets.length : i + 7,
      );

      // Fill the rest of the row if needed
      while (rowWidgets.length < 7) {
        rowWidgets.add(const SizedBox(width: 32, height: 32));
      }

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowWidgets,
        ),
      );
    }

    return Column(
      children: rows
          .map(
            (row) => Padding(padding: const EdgeInsets.only(bottom: 4), child: row),
          )
          .toList(),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateChanged?.call(date);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatMonth(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }
}
