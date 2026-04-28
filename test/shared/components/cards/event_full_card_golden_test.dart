import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_display_entity.dart';
import 'package:lazzo/shared/components/cards/event_full_card.dart';

import '../../../helpers/golden_test_helper.dart';

EventDisplayEntity _buildEvent() {
  return EventDisplayEntity(
    id: 'event-1',
    name: 'Dinner Night',
    emoji: '🍝',
    date: DateTime(2026, 5, 20, 19, 0),
    location: 'Lisbon',
    status: EventDisplayStatus.pending,
    goingCount: 3,
    participantCount: 5,
    attendeeAvatars: const [],
    attendeeNames: const ['Ana', 'Rui', 'Mia'],
  );
}

void main() {
  group('EventFullCard - golden', () {
    testWidgets('pending state', (tester) async {
      await pumpGoldenWidget(
        tester,
        EventFullCard(
          event: _buildEvent(),
          state: EventFullCardState.pending,
        ),
        screenSize: TestScreenSizes.tablet,
      );

      await expectLater(
        find.byType(EventFullCard),
        matchesGoldenFile('goldens/event_full_card_pending.png'),
      );
    });

    testWidgets('confirmed state', (tester) async {
      await pumpGoldenWidget(
        tester,
        EventFullCard(
          event: _buildEvent().copyWith(status: EventDisplayStatus.confirmed),
          state: EventFullCardState.confirmed,
        ),
        screenSize: TestScreenSizes.tablet,
      );

      await expectLater(
        find.byType(EventFullCard),
        matchesGoldenFile('goldens/event_full_card_confirmed.png'),
      );
    });
  });
}
