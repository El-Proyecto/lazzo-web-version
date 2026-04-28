import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_display_entity.dart';
import 'package:lazzo/features/home/domain/entities/participant_photo.dart';
import 'package:lazzo/shared/components/widgets/rsvp_widget.dart';

void main() {
  final vote = RsvpVote(
    id: 'vote-1',
    userId: 'user-1',
    userName: 'Ana',
    status: RsvpVoteStatus.going,
    votedAt: DateTime(2025, 7, 1),
  );
  const photo = ParticipantPhoto(
    userId: 'user-1',
    userName: 'Ana',
    photoCount: 2,
  );

  final baseEntity = EventDisplayEntity(
    id: 'event-1',
    name: 'Event',
    emoji: '🎉',
    date: DateTime(2025, 7, 10),
    location: 'Park',
    status: EventDisplayStatus.pending,
    goingCount: 1,
    participantCount: 1,
    attendeeAvatars: const ['a.png'],
    attendeeNames: const ['Ana'],
    userVote: RsvpVoteStatus.pending,
    allVotes: [vote],
    photoCount: 2,
    maxPhotos: 10,
    participantPhotos: const [photo],
  );

  group('EventDisplayEntity', () {
    test('copyWith updates fields', () {
      final updated = baseEntity.copyWith(
        name: 'Updated',
        status: EventDisplayStatus.confirmed,
        goingCount: 5,
      );

      expect(updated.name, 'Updated');
      expect(updated.status, EventDisplayStatus.confirmed);
      expect(updated.goingCount, 5);
      expect(updated.id, baseEntity.id);
    });

    test('keeps defaults when optional constructor values omitted', () {
      const entity = EventDisplayEntity(
        id: 'event-2',
        name: 'No Optionals',
        emoji: '✅',
        status: EventDisplayStatus.pending,
        goingCount: 0,
        participantCount: 0,
        attendeeAvatars: [],
        attendeeNames: [],
      );

      expect(entity.userVote, RsvpVoteStatus.pending);
      expect(entity.allVotes, isEmpty);
      expect(entity.photoCount, 0);
      expect(entity.maxPhotos, 0);
      expect(entity.participantPhotos, isEmpty);
    });
  });
}
