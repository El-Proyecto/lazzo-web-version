import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/data/fakes/fake_event_repository.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';
import 'package:lazzo/features/create_event/domain/repositories/event_repository.dart';

void main() {
  // ignore: unused_local_variable
  final EventRepository _ = FakeEventRepository();

  late FakeEventRepository repo;

  setUp(() {
    repo = FakeEventRepository();
  });

  group('FakeEventRepository (create_event)', () {
    test('createEvent returns typed Event with generated id', () async {
      final created = await repo.createEvent(
        Event(
          id: '',
          name: 'Novo Evento',
          emoji: ':)',
          status: EventStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      expect(created, isA<Event>());
      expect(created.id, isNotEmpty);
      expect(created.name, 'Novo Evento');
    });

    test('getEventById returns created event', () async {
      final created = await repo.createEvent(
        Event(
          id: '',
          name: 'Evento Lookup',
          emoji: 'P',
          status: EventStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      final loaded = await repo.getEventById(created.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, created.id);
    });

    test('deleteEvent removes previously created event', () async {
      final created = await repo.createEvent(
        Event(
          id: '',
          name: 'Evento Delete',
          emoji: 'X',
          status: EventStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      await repo.deleteEvent(created.id);
      final loaded = await repo.getEventById(created.id);
      expect(loaded, isNull);
    });
  });
}
