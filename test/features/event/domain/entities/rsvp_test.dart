import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';

void main() {
  final baseRsvp = Rsvp(
    id: 'r-1',
    eventId: 'e-1',
    userId: 'u-1',
    userName: 'Ana',
    status: RsvpStatus.pending,
    createdAt: DateTime(2025, 7, 1),
  );

  group('Rsvp.copyWith', () {
    test('updates status', () {
      final updated = baseRsvp.copyWith(status: RsvpStatus.going);
      expect(updated.status, RsvpStatus.going);
    });

    test('preserves null optional fields', () {
      final updated = baseRsvp.copyWith(userName: 'Bia');
      expect(updated.userAvatar, isNull);
      expect(updated.userEmail, isNull);
    });
  });

  group('RsvpStatus', () {
    test('has expected values', () {
      expect(
        RsvpStatus.values,
        containsAll([
          RsvpStatus.going,
          RsvpStatus.notGoing,
          RsvpStatus.maybe,
          RsvpStatus.pending,
        ]),
      );
    });
  });
}
