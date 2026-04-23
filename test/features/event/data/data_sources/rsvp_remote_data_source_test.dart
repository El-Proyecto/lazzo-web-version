import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/data_sources/rsvp_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../mocks/mock_supabase.dart';

class MockRsvpRemoteSupabaseOps extends Mock implements RsvpRemoteSupabaseOps {}

void main() {
  late MockSupabaseClient mockClient;
  late MockRsvpRemoteSupabaseOps mockOps;
  late RsvpRemoteDataSource sut;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockOps = MockRsvpRemoteSupabaseOps();
    sut = RsvpRemoteDataSource(mockClient, ops: mockOps);
  });

  group('RsvpRemoteDataSource', () {
    test('getEventRsvps filters by pevent_id', () async {
      when(() => mockOps.getEventRsvpsRaw('e1')).thenAnswer((_) async => [
        {
          'user_id': 'u1',
          'pevent_id': 'e1',
          'rsvp': 'yes',
          'confirmed_at': '2026-01-01T10:00:00Z',
          'user': {
            'id': 'u1',
            'name': 'Alice',
            'avatar_url': null,
            'email': 'a@a.com',
          },
        },
      ]);

      final result = await sut.getEventRsvps('e1');

      expect(result, hasLength(1));
      verify(() => mockOps.getEventRsvpsRaw('e1')).called(1);
    });

    test('getEventRsvps converts avatar path to signed url', () async {
      when(() => mockOps.createSignedAvatarUrl('avatars/u1.png'))
          .thenAnswer((_) async => 'https://signed');
      when(() => mockOps.getEventRsvpsRaw('e1')).thenAnswer((_) async => [
        {
          'user_id': 'u1',
          'pevent_id': 'e1',
          'rsvp': 'yes',
          'confirmed_at': '2026-01-01T10:00:00Z',
          'user': {
            'id': 'u1',
            'name': 'Alice',
            'avatar_url': 'avatars/u1.png',
            'email': 'a@a.com',
          },
        },
      ]);

      final result = await sut.getEventRsvps('e1');

      expect(result.first.userAvatar, 'https://signed');
      verify(() => mockOps.createSignedAvatarUrl('avatars/u1.png'))
          .called(1);
    });

    test('submitRsvp upserts expected keys', () async {
      when(
        () => mockOps.upsertRsvp(
          eventId: 'e1',
          userId: 'u1',
          status: 'yes',
          confirmedAtIso: any(named: 'confirmedAtIso'),
        ),
      ).thenAnswer((_) async => {
        'user_id': 'u1',
        'pevent_id': 'e1',
        'rsvp': 'yes',
        'confirmed_at': '2026-01-01T10:00:00Z',
        'user': {'id': 'u1', 'name': 'Alice', 'avatar_url': null, 'email': null},
      });

      await sut.submitRsvp('e1', 'u1', 'yes');

      verify(
        () => mockOps.upsertRsvp(
          eventId: 'e1',
          userId: 'u1',
          status: 'yes',
          confirmedAtIso: any(named: 'confirmedAtIso'),
        ),
      ).called(1);
    });

    test('submitRsvp propagates exceptions', () async {
      when(
        () => mockOps.upsertRsvp(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
          status: any(named: 'status'),
          confirmedAtIso: any(named: 'confirmedAtIso'),
        ),
      )
          .thenThrow(Exception('db down'));

      await expectLater(
        () => sut.submitRsvp('e1', 'u1', 'yes'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
