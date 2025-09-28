import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'event_group_selector.dart';
import 'location_section.dart';
import '../../../../shared/components/widgets/grabber_bar.dart';

/// Bottom sheet para confirmar a criação do evento
/// Mostra resumo de todas as informações do evento
class ConfirmEventBottomSheet extends StatelessWidget {
  final String eventName;
  final String eventEmoji;
  final GroupInfo? selectedGroup;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final LocationInfo? selectedLocation;
  final VoidCallback? onCreateEvent;

  const ConfirmEventBottomSheet({
    super.key,
    required this.eventName,
    required this.eventEmoji,
    this.selectedGroup,
    this.selectedDate,
    this.selectedTime,
    this.endDate,
    this.endTime,
    this.selectedLocation,
    this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: keyboardHeight > 0 ? maxHeight : screenHeight * 0.7,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grabber bar
          const Padding(
            padding: EdgeInsets.only(top: Gaps.sm),
            child: Center(child: GrabberBar()),
          ),

          // Header com título e botão fechar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirm Event',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: BrandColors.text2,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content with padding
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                left: Gaps.lg,
                right: Gaps.lg,
                bottom: Gaps.lg + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group
                  _buildInfoRow(
                    'Group',
                    selectedGroup?.name ?? 'No group selected',
                    Icons.group,
                  ),

                  const SizedBox(height: Gaps.md),

                  // Name com emoji
                  _buildNameRow(),

                  const SizedBox(height: Gaps.md),

                  // Date & Time
                  _buildInfoRow(
                    'Date & Time',
                    _formatDateTime(),
                    Icons.schedule,
                  ),

                  const SizedBox(height: Gaps.md),

                  // Location
                  _buildInfoRow(
                    'Location',
                    _formatLocation(),
                    Icons.location_on,
                  ),

                  const SizedBox(height: 24),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCreateEvent?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.planning,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Create',
                        style: AppText.titleMediumEmph.copyWith(
                          color: BrandColors.text1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: const Icon(Icons.event, color: BrandColors.text2, size: 24),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
              const SizedBox(height: 2),
              Text(
                '$eventEmoji ${eventName.isEmpty ? 'Untitled Event' : eventName}',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, color: BrandColors.text2, size: 24),
        ),
        const SizedBox(width: Gaps.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime() {
    if (selectedDate == null && selectedTime == null) {
      return 'Date & time to be decided';
    }

    String result = '';

    if (selectedDate != null) {
      result += _formatDate(selectedDate!);
    }

    if (selectedTime != null) {
      if (result.isNotEmpty) result += ' at ';
      result += _formatTime(selectedTime!);
    }

    // Add end time if available
    if (endTime != null && endTime != selectedTime) {
      result += ' - ${_formatTime(endTime!)}';
    }

    return result.isEmpty ? 'Date & time to be decided' : result;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == tomorrow) {
      return 'Tomorrow';
    } else {
      // Format as "Mon, 15 Sep"
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatLocation() {
    if (selectedLocation == null) {
      return 'Location to be decided';
    }

    // If has custom name, use it
    if (selectedLocation!.displayName != null &&
        selectedLocation!.displayName!.isNotEmpty) {
      return selectedLocation!.displayName!;
    }

    // If has address, use it
    if (selectedLocation!.formattedAddress.isNotEmpty) {
      return selectedLocation!.formattedAddress;
    }

    return 'Location to be decided';
  }
}
