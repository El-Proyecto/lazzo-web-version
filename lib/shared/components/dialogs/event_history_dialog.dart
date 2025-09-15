import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(Gaps.lg),
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Event History',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: BrandColors.text2),
                ),
              ],
            ),

            SizedBox(height: Gaps.md),

            // Lista de eventos
            Flexible(
              child: events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            color: BrandColors.text2,
                            size: 48,
                          ),
                          SizedBox(height: Gaps.sm),
                          Text(
                            'No events yet',
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: events.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: Gaps.sm),
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
                    ),
            ),
          ],
        ),
      ),
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
        padding: EdgeInsets.all(Pads.ctlV),
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

            SizedBox(width: Gaps.sm),

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
                  if (event.lastDate != null) ...[
                    SizedBox(height: 2),
                    Text(
                      'Last: ${_formatDate(event.lastDate!)}',
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Seta
            Icon(Icons.arrow_forward_ios, color: BrandColors.text2, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
