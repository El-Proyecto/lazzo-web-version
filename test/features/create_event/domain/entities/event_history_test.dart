import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/domain/entities/event_history.dart';

void main() {
  group('EventHistory', () {
    test('constructs with required and optional fields', () {
      final history = EventHistory(
        id: 'evt-h1',
        name: 'Pool Party',
        emoji: '🏊',
        startDateTime: DateTime(2025, 8, 10, 14),
        locationId: 'loc-1',
        locationName: 'Club',
        locationAddress: 'Main St',
        latitude: 10.1,
        longitude: 20.2,
        createdAt: DateTime(2025, 8, 1),
      );

      expect(history.id, 'evt-h1');
      expect(history.locationName, 'Club');
      expect(history.latitude, 10.1);
    });

    test('toString exposes key fields', () {
      final history = EventHistory(
        id: 'evt-h2',
        name: 'Dinner',
        emoji: '🍽️',
        startDateTime: DateTime(2025, 9, 10, 20),
        createdAt: DateTime(2025, 9, 1),
      );

      final output = history.toString();

      expect(output, contains('EventHistory'));
      expect(output, contains('evt-h2'));
      expect(output, contains('Dinner'));
    });
  });
}
