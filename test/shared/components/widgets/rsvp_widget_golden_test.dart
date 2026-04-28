import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/shared/components/widgets/rsvp_widget.dart';

import '../../../helpers/golden_test_helper.dart';

void main() {
  group('RsvpWidget - golden', () {
    testWidgets('default pending state', (tester) async {
      await pumpGoldenWidget(
        tester,
        RsvpWidget(
          goingCount: 1,
          notGoingCount: 0,
          maybeCount: 0,
          pendingCount: 1,
          userVote: RsvpVoteStatus.pending,
          onGoingPressed: () {},
          onNotGoingPressed: () {},
          onMaybePressed: () {},
          allVotes: const [],
        ),
        screenSize: TestScreenSizes.tablet,
      );

      await expectLater(
        find.byType(RsvpWidget),
        matchesGoldenFile('goldens/rsvp_widget_default.png'),
      );
    });

    testWidgets('not going with suggestion action', (tester) async {
      await pumpGoldenWidget(
        tester,
        RsvpWidget(
          goingCount: 1,
          notGoingCount: 1,
          maybeCount: 0,
          pendingCount: 0,
          userVote: RsvpVoteStatus.notGoing,
          onGoingPressed: () {},
          onNotGoingPressed: () {},
          onMaybePressed: () {},
          onAddSuggestion: () {},
          allVotes: const [],
        ),
        screenSize: TestScreenSizes.tablet,
      );

      await expectLater(
        find.byType(RsvpWidget),
        matchesGoldenFile('goldens/rsvp_widget_not_going.png'),
      );
    });
  });
}
