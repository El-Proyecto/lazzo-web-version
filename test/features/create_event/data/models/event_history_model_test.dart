import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/data/models/event_history_model.dart';

void main() {
  group('EventHistoryModel', () {
    final fullJson = <String, dynamic>{
      'id': 'event-1',
      'name': 'Jantar',
      'emoji': '🍝',
      'start_datetime': '2025-06-15T20:00:00.000Z',
      'location_id': 'loc-1',
      'created_at': '2025-06-10T10:00:00.000Z',
      'locations': {
        'display_name': 'Restaurante',
        'formatted_address': 'Rua A, 123',
        'latitude': 41.1579,
        'longitude': -8.6291,
      },
    };

    test('fromJson maps event history row', () {
      final model = EventHistoryModel.fromJson(fullJson);

      expect(model.id, 'event-1');
      expect(model.locationId, 'loc-1');
      expect(model.locationName, 'Restaurante');
      expect(model.locationAddress, 'Rua A, 123');
      expect(model.latitude, 41.1579);
      expect(model.longitude, -8.6291);
    });

    test('toEntity maps all fields correctly', () {
      final entity = EventHistoryModel.fromJson(fullJson).toEntity();

      expect(entity.id, 'event-1');
      expect(entity.name, 'Jantar');
      expect(entity.emoji, '🍝');
      expect(entity.locationName, 'Restaurante');
      expect(entity.locationAddress, 'Rua A, 123');
      expect(entity.latitude, 41.1579);
      expect(entity.longitude, -8.6291);
    });

    test('handles null joined location', () {
      final json = Map<String, dynamic>.from(fullJson)..['locations'] = null;
      final model = EventHistoryModel.fromJson(json);

      expect(model.locationName, isNull);
      expect(model.locationAddress, isNull);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
    });
  });
}
