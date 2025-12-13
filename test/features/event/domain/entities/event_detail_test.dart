import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/event/domain/entities/event_detail.dart';

void main() {
  group('EventDetail Planning Status', () {
    // Test data
    final testLocation = EventLocation(
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
        groupId: 'group-1',
        groupName: 'Test Group',
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
