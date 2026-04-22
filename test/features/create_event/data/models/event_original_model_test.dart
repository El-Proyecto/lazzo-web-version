import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/data/models/event_original_model.dart';
import 'package:lazzo/features/create_event/domain/entities/event.dart';

void main() {
  group('EventModel', () {
    final fullJson = <String, dynamic>{
      'id': 'event-1',
      'name': 'Festa',
      'emoji': '🎉',
      'start_datetime': '2025-07-10T18:00:00.000Z',
      'end_datetime': '2025-07-10T23:00:00.000Z',
      'location_id': 'loc-1',
      'status': 'pending',
      'created_by': 'user-1',
      'created_at': '2025-06-01T10:00:00.000Z',
      'description': 'Aniversario',
    };

    test('fromJson parses all fields from full json', () {
      final model = EventModel.fromJson(fullJson);

      expect(model.id, 'event-1');
      expect(model.name, 'Festa');
      expect(model.emoji, '🎉');
      expect(model.startDateTime, DateTime.parse('2025-07-10T18:00:00.000Z'));
      expect(model.endDateTime, DateTime.parse('2025-07-10T23:00:00.000Z'));
      expect(model.locationId, 'loc-1');
      expect(model.status, 'pending');
      expect(model.createdBy, 'user-1');
      expect(model.createdAt, DateTime.parse('2025-06-01T10:00:00.000Z'));
      expect(model.description, 'Aniversario');
    });

    test('fromJson preserves null optional fields', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['start_datetime'] = null
        ..['end_datetime'] = null
        ..['location_id'] = null
        ..['description'] = null;

      final model = EventModel.fromJson(json);
      expect(model.startDateTime, isNull);
      expect(model.endDateTime, isNull);
      expect(model.locationId, isNull);
      expect(model.description, isNull);
    });

    test('toJson serializes supabase keys', () {
      final model = EventModel.fromJson(fullJson);
      final json = model.toJson();

      expect(json['id'], 'event-1');
      expect(json['name'], 'Festa');
      expect(json['created_by'], 'user-1');
      expect(json['location_id'], 'loc-1');
      expect(json['status'], 'pending');
    });

    test('toEntity maps status correctly', () {
      final entity = EventModel.fromJson(fullJson).toEntity();

      expect(entity.status, EventStatus.pending);
      expect(entity.name, 'Festa');
      expect(entity.location, isNull);
    });

    test('round-trip fromJson(toJson).toEntity keeps core fields', () {
      final model = EventModel.fromJson(fullJson);
      final entity = EventModel.fromJson(model.toJson()).toEntity();

      expect(entity.id, 'event-1');
      expect(entity.name, 'Festa');
      expect(entity.emoji, '🎉');
      expect(entity.status, EventStatus.pending);
      expect(entity.createdAt, DateTime.parse('2025-06-01T10:00:00.000Z'));
    });
  });
}
