import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/fakes/fake_event_repository.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';
import 'package:lazzo/features/event/domain/repositories/event_repository.dart';

void main() {
  // ignore: unused_local_variable
  final EventRepository _ = FakeEventRepository();

  late FakeEventRepository repo;

  setUp(() {
    repo = FakeEventRepository();
  });

  group('FakeEventRepository', () {
    test('getEventDetail returns seeded event for event-1', () async {
      final detail = await repo.getEventDetail('event-1');

      expect(detail.id, 'event-1');
      expect(detail.name, isNotEmpty);
      expect(detail.status, isA<EventStatus>());
    });

    test('getEventDetail for unknown id returns sensible non-null detail',
        () async {
      final detail = await repo.getEventDetail('unknown-event');

      expect(detail.id, 'unknown-event');
      expect(detail.name, isNotEmpty);
    });

    test('updateEventStatus persists status for subsequent getEventDetail',
        () async {
      await repo.updateEventStatus('event-1', EventStatus.living);

      final detail = await repo.getEventDetail('event-1');
      expect(detail.status, EventStatus.living);
    });

    test('endEventNow updates endDateTime', () async {
      final ended = await repo.endEventNow('event-1');
      final fetched = await repo.getEventDetail('event-1');

      expect(ended.endDateTime, isNotNull);
      expect(fetched.endDateTime, isNotNull);
    });

    test('extendEventTime adds minutes to endDateTime', () async {
      final before = await repo.getEventDetail('event-1');
      final beforeEnd = before.endDateTime!;

      final updated = await repo.extendEventTime('event-1', 30);

      expect(updated.endDateTime, isNotNull);
      expect(updated.endDateTime!.isAfter(beforeEnd), isTrue);
    });
  });
}
