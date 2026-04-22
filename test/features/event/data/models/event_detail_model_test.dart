import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/models/event_detail_model.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';

void main() {
  group('EventDetailModel', () {
    final fullJson = <String, dynamic>{
      'id': 'event-1',
      'name': 'Sunset',
      'emoji': '🌇',
      'start_datetime': '2025-08-01T18:00:00.000Z',
      'end_datetime': '2025-08-01T20:00:00.000Z',
      'location_name': 'Miradouro',
      'location_address': 'Rua C, 10',
      'location_latitude': 38.7223,
      'location_longitude': -9.1393,
      'status': 'pending',
      'created_at': '2025-07-01T12:00:00.000Z',
      'host_id': 'host-1',
      'rsvp_going_count': 5,
      'rsvp_not_going_count': 2,
      'description': 'Fim de tarde',
    };

    test('fromJson parses full row with counts and host info', () {
      final model = EventDetailModel.fromJson(fullJson);

      expect(model.hostId, 'host-1');
      expect(model.goingCount, 5);
      expect(model.notGoingCount, 2);
      expect(model.locationName, 'Miradouro');
      expect(model.locationLatitude, 38.7223);
    });

    test('fromJson handles null location fields', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['location_name'] = null
        ..['location_address'] = null
        ..['location_latitude'] = null
        ..['location_longitude'] = null;
      final model = EventDetailModel.fromJson(json);

      expect(model.locationName, isNull);
      expect(model.locationAddress, isNull);
      expect(model.locationLatitude, isNull);
      expect(model.locationLongitude, isNull);
    });

    test('fromJson preserves null start and end datetime', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['start_datetime'] = null
        ..['end_datetime'] = null;
      final model = EventDetailModel.fromJson(json);

      expect(model.startDateTime, isNull);
      expect(model.endDateTime, isNull);
    });

    test('toEntity maps hostId and counts correctly', () {
      final entity = EventDetailModel.fromJson(fullJson).toEntity();

      expect(entity.hostId, 'host-1');
      expect(entity.goingCount, 5);
      expect(entity.notGoingCount, 2);
      expect(entity.location, isNotNull);
    });

    test('status string parsing supports pending living recap ended', () {
      final pending = EventDetailModel.fromJson(fullJson).toEntity();
      final living = EventDetailModel.fromJson(
        Map<String, dynamic>.from(fullJson)..['status'] = 'living',
      ).toEntity();
      final recap = EventDetailModel.fromJson(
        Map<String, dynamic>.from(fullJson)..['status'] = 'recap',
      ).toEntity();
      final ended = EventDetailModel.fromJson(
        Map<String, dynamic>.from(fullJson)..['status'] = 'ended',
      ).toEntity();

      expect(pending.status, EventStatus.pending);
      expect(living.status, EventStatus.living);
      expect(recap.status, EventStatus.recap);
      expect(ended.status, EventStatus.ended);
    });
  });
}
