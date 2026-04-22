import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/entities/event_detail.dart';

void main() {
  final baseEvent = EventDetail(
    id: 'event-copy-1',
    name: 'Original Event',
    emoji: '🎉',
    startDateTime: DateTime(2025, 10, 20, 18),
    endDateTime: DateTime(2025, 10, 20, 22),
    location: const EventLocation(
      id: 'loc-base',
      displayName: 'Hall',
      formattedAddress: 'Street 1',
      latitude: 1,
      longitude: 2,
    ),
    status: EventStatus.pending,
    createdAt: DateTime(2025, 10, 1),
    hostId: 'host-1',
    goingCount: 3,
    notGoingCount: 1,
    description: 'desc',
  );

  group('EventDetail.copyWith', () {
    test('updates required and optional fields', () {
      final updated = baseEvent.copyWith(
        id: 'event-copy-2',
        name: 'Updated Event',
        emoji: '🔥',
        startDateTime: DateTime(2025, 11, 1, 20),
        endDateTime: DateTime(2025, 11, 1, 23),
        location: const EventLocation(
          id: 'loc-new',
          displayName: 'Beach',
          formattedAddress: 'Street 2',
          latitude: 3,
          longitude: 4,
        ),
        status: EventStatus.confirmed,
        createdAt: DateTime(2025, 10, 2),
        hostId: 'host-2',
        goingCount: 9,
        notGoingCount: 2,
        description: 'updated desc',
      );

      expect(updated.id, 'event-copy-2');
      expect(updated.name, 'Updated Event');
      expect(updated.emoji, '🔥');
      expect(updated.startDateTime, DateTime(2025, 11, 1, 20));
      expect(updated.endDateTime, DateTime(2025, 11, 1, 23));
      expect(updated.location?.id, 'loc-new');
      expect(updated.status, EventStatus.confirmed);
      expect(updated.createdAt, DateTime(2025, 10, 2));
      expect(updated.hostId, 'host-2');
      expect(updated.goingCount, 9);
      expect(updated.notGoingCount, 2);
      expect(updated.description, 'updated desc');
    });

    test('clears description when clearDescription is true', () {
      final cleared = baseEvent.copyWith(clearDescription: true);
      expect(cleared.description, isNull);
    });

    test('preserves counts and status when unspecified', () {
      final touched = baseEvent.copyWith(name: 'Only Name Changed');
      expect(touched.goingCount, baseEvent.goingCount);
      expect(touched.notGoingCount, baseEvent.notGoingCount);
      expect(touched.status, baseEvent.status);
    });
  });

  group('EventDetail Planning Status', () {
    // Test data
    final testLocation = const EventLocation(
      id: 'loc-1',
      displayName: 'Test Venue',
      formattedAddress: '123 Test St',
      latitude: 40.7128,
      longitude: -74.0060,
    );

    final testDate = DateTime(2025, 12, 20, 14, 0);
    final testEndDate = DateTime(2025, 12, 20, 16, 0);

    EventDetail createTestEvent({
      DateTime? startDateTime,
      DateTime? endDateTime,
      EventLocation? location,
    }) {
      return EventDetail(
        id: 'event-1',
        name: 'Test Event',
        emoji: '🎉',
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: location,
        status: EventStatus.pending,
        createdAt: DateTime.now(),
        hostId: 'host-1',
        goingCount: 0,
        notGoingCount: 0,
      );
    }

    test('isFullyDefined returns true when both location and date are set', () {
      final event = createTestEvent(
        startDateTime: testDate,
        endDateTime: testEndDate,
        location: testLocation,
      );

      expect(event.isFullyDefined, true);
      expect(event.hasDefinedLocation, true);
      expect(event.hasDefinedDate, true);
      expect(event.planningStatus, EventPlanningStatus.bothDefined);
    });

    test('isFullyDefined returns false when only location is set', () {
      final event = createTestEvent(
        location: testLocation,
      );

      expect(event.isFullyDefined, false);
      expect(event.hasDefinedLocation, true);
      expect(event.hasDefinedDate, false);
      expect(event.planningStatus, EventPlanningStatus.partialDefined);
    });

    test('isFullyDefined returns false when only date is set', () {
      final event = createTestEvent(
        startDateTime: testDate,
        endDateTime: testEndDate,
      );

      expect(event.isFullyDefined, false);
      expect(event.hasDefinedLocation, false);
      expect(event.hasDefinedDate, true);
      expect(event.planningStatus, EventPlanningStatus.partialDefined);
    });

    test('isFullyDefined returns false when neither location nor date are set',
        () {
      final event = createTestEvent();

      expect(event.isFullyDefined, false);
      expect(event.hasDefinedLocation, false);
      expect(event.hasDefinedDate, false);
      expect(event.planningStatus, EventPlanningStatus.noneDefined);
    });

    test('hasDefinedLocation returns true only when location is set', () {
      final eventWithLocation = createTestEvent(location: testLocation);
      final eventWithoutLocation = createTestEvent();

      expect(eventWithLocation.hasDefinedLocation, true);
      expect(eventWithoutLocation.hasDefinedLocation, false);
    });

    test('hasDefinedDate returns true only when startDateTime is set', () {
      final eventWithDate = createTestEvent(
        startDateTime: testDate,
        endDateTime: testEndDate,
      );
      final eventWithoutDate = createTestEvent();

      expect(eventWithDate.hasDefinedDate, true);
      expect(eventWithoutDate.hasDefinedDate, false);
    });

    test('planningStatus returns correct status for all combinations', () {
      // Both defined
      expect(
        createTestEvent(
          startDateTime: testDate,
          endDateTime: testEndDate,
          location: testLocation,
        ).planningStatus,
        EventPlanningStatus.bothDefined,
      );

      // Only location
      expect(
        createTestEvent(location: testLocation).planningStatus,
        EventPlanningStatus.partialDefined,
      );

      // Only date
      expect(
        createTestEvent(
          startDateTime: testDate,
          endDateTime: testEndDate,
        ).planningStatus,
        EventPlanningStatus.partialDefined,
      );

      // Neither
      expect(
        createTestEvent().planningStatus,
        EventPlanningStatus.noneDefined,
      );
    });
  });
}
