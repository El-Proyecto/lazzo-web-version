import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/fakes/fake_rsvp_repository.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';
import 'package:lazzo/features/event/domain/repositories/rsvp_repository.dart';

void main() {
  // ignore: unused_local_variable
  final RsvpRepository _ = FakeRsvpRepository();

  late FakeRsvpRepository repo;

  setUp(() {
    repo = FakeRsvpRepository();
  });

  group('FakeRsvpRepository', () {
    test('getEventRsvps returns seeded list for event-1', () async {
      final rsvps = await repo.getEventRsvps('event-1');

      expect(rsvps, isNotEmpty);
      expect(rsvps.every((r) => r.eventId == 'event-1'), isTrue);
    });

    test('submitRsvp creates new RSVP', () async {
      final userId = 'new-user-${DateTime.now().microsecondsSinceEpoch}';

      final created = await repo.submitRsvp('event-1', userId, RsvpStatus.going);

      expect(created.userId, userId);
      expect(created.status, RsvpStatus.going);
    });

    test('submitRsvp is idempotent update on same userId', () async {
      const userId = 'idempotent-user';
      await repo.submitRsvp('event-1', userId, RsvpStatus.going);

      final updated =
          await repo.submitRsvp('event-1', userId, RsvpStatus.notGoing);
      final all = await repo.getEventRsvps('event-1');
      final matches = all.where((r) => r.userId == userId).toList();

      expect(updated.status, RsvpStatus.notGoing);
      expect(matches, hasLength(1));
    });

    test('getUserRsvp returns null for unknown user', () async {
      final rsvp = await repo.getUserRsvp('event-1', 'unknown-user');
      expect(rsvp, isNull);
    });

    test('getRsvpsByStatus filters by status', () async {
      final going = await repo.getRsvpsByStatus('event-1', RsvpStatus.going);
      expect(going, isNotEmpty);
      expect(going.every((r) => r.status == RsvpStatus.going), isTrue);
    });
  });
}
