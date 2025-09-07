import 'package:flutter/material.dart';
import '../../domain/entities/pending_event.dart';
import '../../../../shared/components/cards/pending_event_card.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import 'package:intl/intl.dart';

class StackedPendingEventsCard extends StatelessWidget {
  final List<PendingEvent> events;
  final VoidCallback? onTap;

  const StackedPendingEventsCard({super.key, required this.events, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    // Show the top event (closest date)
    final topEvent = events.first;
    final stackCount = events.length;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Background cards (stacked effect)
          if (stackCount > 1)
            Positioned(
              top: 4,
              right: 4,
              left: 4,
              child: Container(
                height: 94,
                decoration: ShapeDecoration(
                  color: BrandColors.bg2.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),
          if (stackCount > 2)
            Positioned(
              top: 8,
              right: 8,
              left: 8,
              child: Container(
                height: 94,
                decoration: ShapeDecoration(
                  color: BrandColors.bg2.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),

          // Top card (main event)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: PendingEventCard(
              emoji: topEvent.emoji,
              title: topEvent.title,
              dateTime: _formatDateTime(topEvent.scheduledDate),
              location: topEvent.location,
              voteButton: _buildStackIndicator(stackCount),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM, HH:mm').format(dateTime);
  }

  Widget _buildStackIndicator(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: BrandColors.planning,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      child: Text(
        '$count events',
        style: const TextStyle(
          color: BrandColors.text1,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
