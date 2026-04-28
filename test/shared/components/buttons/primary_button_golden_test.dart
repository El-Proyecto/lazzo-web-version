import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/shared/components/buttons/green_button.dart';

import '../../../helpers/golden_test_helper.dart';

void main() {
  group('GreenButton (primary) - golden', () {
    testWidgets('enabled state', (tester) async {
      await pumpGoldenWidget(
        tester,
        GreenButton(
          text: 'Continue',
          onPressed: () {},
        ),
        screenSize: TestScreenSizes.phone,
      );

      await expectLater(
        find.byType(GreenButton),
        matchesGoldenFile('goldens/primary_button_enabled.png'),
      );
    });

    testWidgets('disabled state', (tester) async {
      await pumpGoldenWidget(
        tester,
        const GreenButton(
          text: 'Continue',
          onPressed: null,
        ),
        screenSize: TestScreenSizes.phone,
      );

      await expectLater(
        find.byType(GreenButton),
        matchesGoldenFile('goldens/primary_button_disabled.png'),
      );
    });
  });
}
