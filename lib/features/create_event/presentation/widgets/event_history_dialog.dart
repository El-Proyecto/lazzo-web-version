import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/common_bottom_sheet.dart';

/// Bottom sheet para exibir histórico de eventos
/// Permite selecionar um evento anterior para usar como template
class EventHistoryBottomSheet extends StatelessWidget {
  final List<EventHistoryItem> events;
  final Function(EventHistoryItem)? onEventSelected;

  const EventHistoryBottomSheet({
    super.key,
    required this.events,
    this.onEventSelected,
  });

  /// Show event history bottom sheet
  static Future<void> show({
    required BuildContext context,
    required List<EventHistoryItem> events,
    Function(EventHistoryItem)? onEventSelected,
  }) {
    return CommonBottomSheet.show(
      context: context,
      title: 'Event History',
      maxHeight: 400,
      content: EventHistoryBottomSheet(
        events: events,
        onEventSelected: onEventSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              color: BrandColors.text2,
              size: 48,
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              'No events yet',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: Gaps.sm),
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventHistoryTile(
          event: event,
          onTap: () {
            Navigator.of(context).pop();
            onEventSelected?.call(event);
          },
        );
      },
    );
  }
}

class _EventHistoryTile extends StatelessWidget {
  final EventHistoryItem event;
  final VoidCallback? onTap;

  const _EventHistoryTile({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.smAlt),
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
        child: Row(
          children: [
            // Ícone do evento
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Center(
                child: Text(event.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(width: Gaps.sm),

            // Nome e data
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: AppText.bodyLarge.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (event.lastTime != null || event.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeAndLocation(event.lastTime, event.location),
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Seta
            const Icon(Icons.arrow_forward_ios,
                color: BrandColors.text2, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatTimeAndLocation(TimeOfDay? time, String? location) {
    final parts = <String>[];

    if (time != null) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      parts.add('$hour:$minute');
    }

    if (location != null && location.isNotEmpty) {
      parts.add(location);
    }

    return parts.join(' • ');
  }
}

/// Modelo para item do histórico de eventos
class EventHistoryItem {
  final String id;
  final String name;
  final String emoji;
  final DateTime? lastDate;
  final TimeOfDay? lastTime;
  final String? location;
  final String? groupId;

  const EventHistoryItem({
    required this.id,
    required this.name,
    required this.emoji,
    this.lastDate,
    this.lastTime,
    this.location,
    this.groupId,
  });
}
