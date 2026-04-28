import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazzo/features/create_event/domain/entities/event_history.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';
import 'package:lazzo/features/create_event/presentation/pages/create_event_page.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/golden_test_helper.dart';

class MockCreateEventRepository extends Mock implements EventRepository {}

void main() {
  late MockCreateEventRepository mockRepository;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('posthog_flutter'), (_) async => null);
  });

  setUp(() {
    mockRepository = MockCreateEventRepository();
    when(() => mockRepository.getCurrentLocation())
        .thenAnswer((_) async => null);
    when(() => mockRepository.getEventById(any()))
        .thenAnswer((_) async => null);
    when(() => mockRepository.searchLocations(any()))
        .thenAnswer((_) async => []);
    when(
      () => mockRepository.getUserEventHistory(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => <EventHistory>[]);
  });

  group('CreateEventPage - golden', () {
    testWidgets('empty state', (tester) async {
      await pumpGoldenWidget(
        tester,
        ProviderScope(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockRepository)
          ],
          child: const CreateEventPage(),
        ),
        screenSize: TestScreenSizes.phone,
      );

      await expectLater(
        find.byType(CreateEventPage),
        matchesGoldenFile('goldens/create_event_page_empty.png'),
      );
    });
  });
}
