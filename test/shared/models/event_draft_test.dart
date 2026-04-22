import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/shared/models/event_draft.dart';

void main() {
  group('EventDraft', () {
    test('is valid when name exists and end is after start', () {
      // Arrange
      final draft = EventDraft(
        eventName: 'Jantar Amigos',
        selectedDate: DateTime(2026, 1, 10),
        selectedTime: const TimeOfDay(hour: 20, minute: 0),
        endDate: DateTime(2026, 1, 10),
        endTime: const TimeOfDay(hour: 22, minute: 0),
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      final isValid = draft.isValid;

      // Assert
      expect(isValid, isTrue);
    });

    test('is invalid when event name is empty after trim', () {
      // Arrange
      final draft = EventDraft(
        eventName: '   ',
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      final isValid = draft.isValid;

      // Assert
      expect(isValid, isFalse);
    });

    test('is invalid when end date-time is not after start date-time', () {
      // Arrange
      final draft = EventDraft(
        eventName: 'Evento',
        selectedDate: DateTime(2026, 2, 10),
        selectedTime: const TimeOfDay(hour: 10, minute: 0),
        endDate: DateTime(2026, 2, 10),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        createdAt: DateTime(2026, 1, 1),
      );

      // Act
      final isValid = draft.isValid;

      // Assert
      expect(isValid, isFalse);
    });

    test('serializes and deserializes preserving key fields', () {
      // Arrange
      final createdAt = DateTime(2026, 3, 1, 12, 30);
      final draft = EventDraft(
        eventName: 'Festa',
        eventEmoji: '🎉',
        selectedDate: DateTime(2026, 3, 10),
        selectedTime: const TimeOfDay(hour: 18, minute: 45),
        endDate: DateTime(2026, 3, 10),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        createdAt: createdAt,
      );

      // Act
      final encoded = draft.toJson();
      final decoded = EventDraft.fromJson(encoded);

      // Assert
      expect(decoded.eventName, draft.eventName);
      expect(decoded.eventEmoji, draft.eventEmoji);
      expect(decoded.selectedDate, draft.selectedDate);
      expect(decoded.selectedTime, draft.selectedTime);
      expect(decoded.endDate, draft.endDate);
      expect(decoded.endTime, draft.endTime);
      expect(decoded.createdAt, draft.createdAt);
    });
  });
}
