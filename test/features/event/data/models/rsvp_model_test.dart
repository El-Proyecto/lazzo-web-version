import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/models/rsvp_model.dart';
import 'package:lazzo/features/event/domain/entities/rsvp.dart';

void main() {
  group('RsvpModel', () {
    final fullJson = <String, dynamic>{
      'user_id': 'user-1',
      'pevent_id': 'event-1',
      'rsvp': 'yes',
      'confirmed_at': '2025-06-15T20:00:00.000Z',
      'user': {
        'name': 'Alice',
        'avatar_url': 'https://example.com/alice.jpg',
        'email': 'alice@example.com',
      },
    };

    group('fromJson', () {
      test('parses all fields from full JSON', () {
        final model = RsvpModel.fromJson(fullJson);

        expect(model.userId, 'user-1');
        expect(model.eventId, 'event-1');
        expect(model.status, 'yes');
        expect(model.userName, 'Alice');
        expect(model.userAvatar, 'https://example.com/alice.jpg');
        expect(model.userEmail, 'alice@example.com');
        expect(model.confirmedAt, isNotNull);
      });

      test('handles missing user join gracefully', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('user');
        final model = RsvpModel.fromJson(json);

        expect(model.userName, 'Unknown User');
        expect(model.userAvatar, isNull);
      });

      test('handles null confirmed_at', () {
        final json = Map<String, dynamic>.from(fullJson)..['confirmed_at'] = null;
        final model = RsvpModel.fromJson(json);

        expect(model.confirmedAt, isNull);
      });

      test('defaults rsvp to pending when column is absent', () {
        final json = Map<String, dynamic>.from(fullJson)..remove('rsvp');
        final model = RsvpModel.fromJson(json);

        expect(model.status, 'pending');
      });
    });

    group('toEntity', () {
      test('maps yes to going', () {
        final entity = RsvpModel.fromJson(fullJson).toEntity();
        expect(entity.status, RsvpStatus.going);
      });

      test('maps no to notGoing', () {
        final json = Map<String, dynamic>.from(fullJson)..['rsvp'] = 'no';
        final entity = RsvpModel.fromJson(json).toEntity();
        expect(entity.status, RsvpStatus.notGoing);
      });

      test('maps maybe to maybe', () {
        final json = Map<String, dynamic>.from(fullJson)..['rsvp'] = 'maybe';
        final entity = RsvpModel.fromJson(json).toEntity();
        expect(entity.status, RsvpStatus.maybe);
      });

      test('maps unknown value to pending', () {
        final json = Map<String, dynamic>.from(fullJson)..['rsvp'] = 'pending';
        final entity = RsvpModel.fromJson(json).toEntity();
        expect(entity.status, RsvpStatus.pending);
      });
    });

    group('toJson', () {
      test('includes user_id pevent_id and rsvp', () {
        final model = RsvpModel.fromJson(fullJson);
        final json = model.toJson();

        expect(json['user_id'], 'user-1');
        expect(json['pevent_id'], 'event-1');
        expect(json['rsvp'], 'yes');
      });

      test('omits confirmed_at when null', () {
        final output = RsvpModel.fromJson(
          Map<String, dynamic>.from(fullJson)..['confirmed_at'] = null,
        ).toJson();
        expect(output.containsKey('confirmed_at'), isFalse);
      });
    });
  });
}
