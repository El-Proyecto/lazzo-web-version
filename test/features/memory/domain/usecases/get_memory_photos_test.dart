import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/domain/entities/memory_entity.dart';
import 'package:lazzo/features/memory/domain/repositories/memory_repository.dart';
import 'package:lazzo/features/memory/domain/usecases/get_memory_photos.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoryRepository extends Mock implements MemoryRepository {}

void main() {
  late MockMemoryRepository mockRepository;
  late GetMemoryPhotos sut;

  setUp(() {
    mockRepository = MockMemoryRepository();
    sut = GetMemoryPhotos(mockRepository);
  });

  group('GetMemoryPhotos', () {
    test('returns cover photos first then grid photos', () async {
      // Arrange
      final cover = MemoryPhoto(
        id: 'cover',
        url: 'cover.jpg',
        voteCount: 10,
        capturedAt: DateTime(2026, 1, 1, 11),
        aspectRatio: 1,
        uploaderId: 'u1',
        uploaderName: 'Alice',
        isCover: true,
      );
      final grid = MemoryPhoto(
        id: 'grid',
        url: 'grid.jpg',
        voteCount: 0,
        capturedAt: DateTime(2026, 1, 1, 12),
        aspectRatio: 1,
        uploaderId: 'u1',
        uploaderName: 'Alice',
        isCover: false,
      );
      final memory = MemoryEntity(
        id: 'm-1',
        eventId: 'event-1',
        title: 'Memory',
        emoji: '📸',
        eventDate: DateTime(2026, 1, 1),
        photos: [grid, cover],
        status: EventStatus.ended,
        createdBy: 'host-1',
      );
      when(() => mockRepository.getMemoryById('m-1'))
          .thenAnswer((_) async => memory);

      // Act
      final result = await sut.call('m-1');

      // Assert
      expect(result, [cover, grid]);
      verify(() => mockRepository.getMemoryById('m-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('throws when memory is not found', () {
      // Arrange
      when(() => mockRepository.getMemoryById('missing'))
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(() => sut.call('missing'), throwsA(isA<Exception>()));
    });
  });
}
