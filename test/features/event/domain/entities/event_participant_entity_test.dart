import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_participant_entity.dart';

void main() {
  group('EventParticipantEntity', () {
    test('constructs with required fields and nullable avatar', () {
      const participant = EventParticipantEntity(
        userId: 'u-1',
        displayName: 'Ana',
        avatarUrl: null,
        status: 'confirmed',
      );

      expect(participant.userId, 'u-1');
      expect(participant.displayName, 'Ana');
      expect(participant.avatarUrl, isNull);
      expect(participant.status, 'confirmed');
    });
  });
}
