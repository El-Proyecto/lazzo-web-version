import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';

void main() {
  const baseLocation = EventLocation(
    id: 'loc-1',
    displayName: 'Parque',
    formattedAddress: 'Rua A',
    latitude: 1.0,
    longitude: 2.0,
  );

  final baseEvent = Event(
    id: 'evt-1',
    name: 'BBQ',
    emoji: '🍖',
    status: EventStatus.pending,
    createdAt: DateTime(2025, 6, 1),
  );

  group('Event.copyWith', () {
    test('updates individual string fields', () {
      final updated = baseEvent.copyWith(name: 'Beach BBQ', emoji: '🏖️');

      expect(updated.name, 'Beach BBQ');
      expect(updated.emoji, '🏖️');
      expect(updated.id, baseEvent.id);
    });

    test('clears nullable fields with ValueWrapper(null)', () {
      final withNullableFields = baseEvent.copyWith(
        startDateTime: ValueWrapper(DateTime(2025, 7, 1)),
        endDateTime: ValueWrapper(DateTime(2025, 7, 1, 22)),
        location: const ValueWrapper(baseLocation),
        description: const ValueWrapper('desc'),
      );

      final cleared = withNullableFields.copyWith(
        startDateTime: const ValueWrapper(null),
        endDateTime: const ValueWrapper(null),
        location: const ValueWrapper(null),
        description: const ValueWrapper(null),
      );

      expect(cleared.startDateTime, isNull);
      expect(cleared.endDateTime, isNull);
      expect(cleared.location, isNull);
      expect(cleared.description, isNull);
    });

    test('preserves nullable field when wrapper is omitted', () {
      final withDate = baseEvent.copyWith(
        startDateTime: ValueWrapper(DateTime(2025, 7, 1)),
      );

      final touched = withDate.copyWith(name: 'Updated');

      expect(touched.startDateTime, DateTime(2025, 7, 1));
    });
  });

  group('EventStatus', () {
    test('contains expected values', () {
      expect(
        EventStatus.values,
        containsAll([
          EventStatus.pending,
          EventStatus.confirmed,
          EventStatus.living,
          EventStatus.recap,
          EventStatus.expired,
        ]),
      );
    });
  });

  group('EventLocation', () {
    test('can be constructed with const', () {
      const location = EventLocation(
        id: 'loc-2',
        displayName: 'Praia',
        formattedAddress: 'Rua B',
        latitude: 12.3,
        longitude: 45.6,
      );

      expect(location.displayName, 'Praia');
    });
  });
}
