import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/shared/components/sections/section_header.dart';

import '../../../helpers/golden_test_helper.dart';

void main() {
  group('SectionHeader - golden', () {
    testWidgets('default title', (tester) async {
      await pumpGoldenWidget(
        tester,
        const Align(
          alignment: Alignment.centerLeft,
          child: SectionHeader('Upcoming events'),
        ),
        screenSize: TestScreenSizes.phone,
      );

      await expectLater(
        find.byType(SectionHeader),
        matchesGoldenFile('goldens/section_header_default.png'),
      );
    });

    testWidgets('long title', (tester) async {
      await pumpGoldenWidget(
        tester,
        const Align(
          alignment: Alignment.centerLeft,
          child: SectionHeader('Upcoming events and memories this week'),
        ),
        screenSize: TestScreenSizes.phone,
      );

      await expectLater(
        find.byType(SectionHeader),
        matchesGoldenFile('goldens/section_header_long_title.png'),
      );
    });
  });
}
