import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/domain/entities/memory_entity.dart';

void main() {
  final older = MemoryPhoto(
    id: 'p-1',
    url: 'u1',
    voteCount: 1,
    capturedAt: DateTime(2025, 1, 1, 9),
    aspectRatio: 1.2,
    uploaderId: 'u-1',
    uploaderName: 'Ana',
    isCover: false,
  );
  final newer = MemoryPhoto(
    id: 'p-2',
    url: 'u2',
    voteCount: 2,
    capturedAt: DateTime(2025, 1, 1, 10),
    aspectRatio: 0.9,
    uploaderId: 'u-2',
    uploaderName: 'Bia',
    isCover: false,
  );
  final cover = MemoryPhoto(
    id: 'p-cover',
    url: 'u3',
    voteCount: 3,
    capturedAt: DateTime(2025, 1, 1, 11),
    aspectRatio: 1.0,
    uploaderId: 'u-3',
    uploaderName: 'Caio',
    isCover: true,
  );

  MemoryEntity buildMemory({
    required EventStatus status,
    DateTime? endDatetime,
  }) {
    return MemoryEntity(
      id: 'm-1',
      eventId: 'e-1',
      title: 'Memory',
      emoji: '📷',
      eventDate: DateTime(2025, 1, 1),
      endDatetime: endDatetime,
      photos: [newer, cover, older],
      status: status,
      createdBy: 'host-1',
    );
  }

  group('MemoryEntity', () {
    test('coverPhotos returns only photos with isCover true', () {
      final entity = buildMemory(status: EventStatus.living);
      expect(entity.coverPhotos.map((e) => e.id), ['p-cover']);
    });

    test('gridPhotos excludes cover photos and sorts by capturedAt', () {
      final entity = buildMemory(status: EventStatus.living);
      expect(entity.gridPhotos.map((e) => e.id), ['p-1', 'p-2']);
    });

    test('recapTimeRemaining returns null when status is not recap', () {
      final entity = buildMemory(
        status: EventStatus.living,
        endDatetime: DateTime.now(),
      );
      expect(entity.recapTimeRemaining, isNull);
    });

    test('recapTimeRemaining returns Duration.zero when window passed', () {
      final entity = buildMemory(
        status: EventStatus.recap,
        endDatetime: DateTime.now().subtract(const Duration(hours: 30)),
      );
      expect(entity.recapTimeRemaining, Duration.zero);
    });
  });

  group('EventStatus.fromString', () {
    test('returns living for valid value', () {
      expect(EventStatus.fromString('living'), EventStatus.living);
    });

    test('falls back to ended for unknown value', () {
      expect(EventStatus.fromString('unknown'), EventStatus.ended);
    });
  });
}
