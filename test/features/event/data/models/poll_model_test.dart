import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/models/poll_model.dart';
import 'package:lazzo/features/event/domain/entities/poll.dart';

void main() {
  group('PollModel', () {
    final fullJson = <String, dynamic>{
      'id': 'poll-1',
      'event_id': 'event-1',
      'type': 'date',
      'question': 'Qual data?',
      'created_at': '2025-06-15T20:00:00.000Z',
      'created_by': 'user-1',
      'options': [
        {
          'id': 'opt-1',
          'poll_id': 'poll-1',
          'value': 'Sabado',
          'vote_count': 3,
        },
        {
          'id': 'opt-2',
          'poll_id': 'poll-1',
          'value': 'Domingo',
          'vote_count': 1,
        },
      ],
    };

    test('fromJson parses options list correctly', () {
      final model = PollModel.fromJson(fullJson);

      expect(model.options, hasLength(2));
      expect(model.options.first.id, 'opt-1');
      expect(model.options.first.voteCount, 3);
    });

    test('fromJson returns empty options list when options is empty', () {
      final model = PollModel.fromJson(
        Map<String, dynamic>.from(fullJson)..['options'] = <dynamic>[],
      );

      expect(model.options, isEmpty);
    });

    test('toEntity maps voteCount and votedUserIds for each option', () {
      final entity = PollModel.fromJson(fullJson).toEntity();

      expect(entity.type, PollType.date);
      expect(entity.options, hasLength(2));
      expect(entity.options.first.voteCount, 3);
      expect(entity.options.first.votedUserIds, isEmpty);
    });
  });
}
