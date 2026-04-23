import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/data/data_sources/event_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../mocks/mock_supabase.dart';

class MockEventRemoteSupabaseOps extends Mock implements EventRemoteSupabaseOps {}

void main() {
  late MockSupabaseClient mockClient;
  late MockEventRemoteSupabaseOps mockOps;
  late EventRemoteDataSource sut;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockOps = MockEventRemoteSupabaseOps();
    sut = EventRemoteDataSource(mockClient, ops: mockOps);
    when(() => mockOps.getEventRsvpRows(any())).thenAnswer((_) async => []);
    when(() => mockOps.resetExpiredVotes(any())).thenAnswer((_) async {});
    when(() => mockOps.updateEventStatus(any(), any())).thenAnswer((_) async {});
    when(() => mockOps.updateEventEndDatetime(any(), any()))
        .thenAnswer((_) async {});
  });

  group('EventRemoteDataSource', () {
    test('getEventDetail queries events table with correct eventId', () async {
      when(() => mockOps.getEventDetailRow('event-1'))
          .thenAnswer((_) async => _eventRow());
      when(() => mockOps.getLocationRow(any())).thenAnswer((_) async => null);

      final result = await sut.getEventDetail('event-1');

      expect(result.id, 'event-1');
      verify(() => mockOps.getEventDetailRow('event-1')).called(1);
    });

    test('getEventDetail triggers resetExpiredEventVotes fire-and-forget',
        () async {
      when(() => mockOps.getEventDetailRow('event-1'))
          .thenAnswer((_) async => _eventRow(status: 'pending'));
      when(() => mockOps.resetExpiredVotes('event-1'))
          .thenThrow(Exception('ignore'));
      when(() => mockOps.getLocationRow(any())).thenAnswer((_) async => null);

      await sut.getEventDetail('event-1');

      verify(() => mockOps.resetExpiredVotes('event-1')).called(1);
    });

    test('updateEventStatus updates events status column', () async {
      when(() => mockOps.getEventStatusDates('event-1'))
          .thenAnswer((_) async => {'start_datetime': null, 'end_datetime': null});
      when(() => mockOps.verifyEventStatus('event-1'))
          .thenAnswer((_) async => {'id': 'event-1', 'name': 'X', 'status': 'planning'});
      when(() => mockOps.getEventDetailRow('event-1'))
          .thenAnswer((_) async => _eventRow(status: 'planning'));
      when(() => mockOps.getLocationRow(any())).thenAnswer((_) async => null);

      await sut.updateEventStatus('event-1', 'planning');

      verify(() => mockOps.updateEventStatus('event-1', 'planning')).called(1);
    });

    test('endEventNow updates events table end_datetime', () async {
      when(() => mockOps.getEventDetailRow('event-1'))
          .thenAnswer((_) async => _eventRow(status: 'pending'));
      when(() => mockOps.getLocationRow(any())).thenAnswer((_) async => null);

      await sut.endEventNow('event-1');

      verify(() => mockOps.updateEventEndDatetime(
            'event-1',
            any(that: isA<String>()),
          ))
          .called(1);
    });

    test('extendEventTime sends updated end_datetime', () async {
      when(() => mockOps.getEventDetailRow('event-1'))
          .thenAnswer((_) async => _eventRow(endDatetime: '2026-01-01T12:00:00Z'));
      when(() => mockOps.getLocationRow(any())).thenAnswer((_) async => null);

      await sut.extendEventTime('event-1', 60);

      verify(() => mockOps.updateEventEndDatetime(
            'event-1',
            any(that: contains('2026-01-01T13:00:00')),
          ))
          .called(1);
    });
  });
}

Map<String, dynamic> _eventRow({
  String? endDatetime,
  String status = 'pending',
}) {
  return {
    'id': 'event-1',
    'name': 'My Event',
    'emoji': '🎉',
    'description': null,
    'start_datetime': null,
    'end_datetime': endDatetime,
    'status': status,
    'location_id': null,
    'created_by': 'host-1',
    'created_at': '2026-01-01T00:00:00Z',
  };
}

