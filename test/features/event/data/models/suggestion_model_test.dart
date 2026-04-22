import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/models/suggestion_model.dart';

void main() {
  group('SuggestionModel', () {
    final fullJson = <String, dynamic>{
      'id': 'sug-1',
      'event_id': 'event-1',
      'created_by': 'user-1',
      'starts_at': '2025-07-20T18:00:00.000Z',
      'ends_at': '2025-07-20T20:00:00.000Z',
      'created_at': '2025-07-10T10:00:00.000Z',
      'user': {
        'name': 'Alice',
        'avatar_url': 'avatar.png',
      },
    };

    test('fromJson parses full row', () {
      final model = SuggestionModel.fromJson(fullJson);

      expect(model.id, 'sug-1');
      expect(model.eventId, 'event-1');
      expect(model.userId, 'user-1');
      expect(model.userName, 'Alice');
      expect(model.userAvatar, 'avatar.png');
      expect(model.endDateTime, DateTime.parse('2025-07-20T20:00:00.000Z'));
    });

    test('fromJson handles null optional fields', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['ends_at'] = null
        ..['user'] = null;
      final model = SuggestionModel.fromJson(json);

      expect(model.endDateTime, isNull);
      expect(model.userAvatar, isNull);
      expect(model.userName, 'Unknown User');
    });

    test('toEntity maps fields correctly', () {
      final entity = SuggestionModel.fromJson(fullJson).toEntity();

      expect(entity.id, 'sug-1');
      expect(entity.eventId, 'event-1');
      expect(entity.userId, 'user-1');
      expect(entity.userName, 'Alice');
      expect(entity.endDateTime, DateTime.parse('2025-07-20T20:00:00.000Z'));
    });
  });
}
