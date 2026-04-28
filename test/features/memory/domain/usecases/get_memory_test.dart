import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/domain/entities/memory_entity.dart';
import 'package:lazzo/features/memory/domain/repositories/memory_repository.dart';
import 'package:lazzo/features/memory/domain/usecases/get_memory.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoryRepository extends Mock implements MemoryRepository {}

void main() {
  late MockMemoryRepository mockRepository;
  late GetMemory sut;

  setUp(() {
    mockRepository = MockMemoryRepository();
    sut = GetMemory(mockRepository);
  });

  group('GetMemory', () {
    test('calls repository and returns memory', () async {
      // Arrange
      final expected = MemoryEntity(
        id: 'm-1',
        eventId: 'event-1',
        title: 'Memory',
        emoji: '📸',
        eventDate: DateTime(2026, 1, 1),
        photos: const [],
        status: EventStatus.ended,
        createdBy: 'host-1',
      );
      when(() => mockRepository.getMemoryById('m-1'))
          .thenAnswer((_) async => expected);

      // Act
      final result = await sut.call('m-1');

      // Assert
      expect(result, expected);
      verify(() => mockRepository.getMemoryById('m-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.getMemoryById(any()))
          .thenThrow(Exception('network'));

      // Act & Assert
      expect(() => sut.call('m-1'), throwsA(isA<Exception>()));
    });
  });
}
