import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pending_event.dart';
import '../providers/pending_event_providers.dart';
import '../widgets/pending_event_widget.dart';
import '../widgets/stacked_pending_events_card.dart';
import '../../../../shared/components/sections/section_block.dart';
import '../../../../shared/constants/spacing.dart';

class PendingEventsSection extends ConsumerWidget {
  const PendingEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingEventsAsync = ref.watch(pendingEventsControllerProvider);
    final isStacked = ref.watch(stackedEventsStateProvider);
    final stackedNotifier = ref.read(stackedEventsStateProvider.notifier);

    return pendingEventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          
          return SectionBlock(
            title: 'Pending Events',
            child: Padding(
              padding: const EdgeInsets.all(Pads.ctlV),
              child: Text(
                'There is no pending events at the moment',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        return SectionBlock(
          title: 'Pending Events',
          child: _buildEventsContent(events, isStacked, stackedNotifier),
        );
      },
      loading: () => SectionBlock(
        title: 'Pending Events',
        child: Padding(
          padding: const EdgeInsets.all(Pads.ctlV),
          child: SizedBox(
            height: 94,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) {
        return SectionBlock(
          title: 'Pending Events',
          child: Padding(
            padding: const EdgeInsets.all(Pads.ctlV),
            child: Text(
              'Failed to load pending events',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsContent(
    List<PendingEvent> events,
    bool isStacked,
    StackedEventsNotifier stackedNotifier,
  ) {
    // Single event - always show expanded
    if (events.length == 1) {
      return PendingEventWidget(event: events.first);
    }

    // Multiple events - show stacked or expanded
    if (isStacked) {
      return StackedPendingEventsCard(
        events: events,
        onTap: () => stackedNotifier.toggleStacking(),
      );
    } else {
      // Show all events expanded (no tap to re-stack option)
      return Column(
        children: [
          // All events
          ...events.map((event) {
            final isLast = events.last == event;
            return Column(
              children: [
                PendingEventWidget(event: event),
                if (!isLast) const SizedBox(height: Gaps.xs),
              ],
            );
          }),
        ],
      );
    }
  }
}
