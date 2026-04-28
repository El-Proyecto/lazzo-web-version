import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/domain/repositories/memory_repository.dart';
import 'package:lazzo/features/memory/domain/usecases/update_memory_cover.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoryRepository extends Mock implements MemoryRepository {}

void main() {
  late MockMemoryRepository mockRepository;
  late UpdateMemoryCover sut;

  setUp(() {
    mockRepository = MockMemoryRepository();
    sut = UpdateMemoryCover(mockRepository);
  });

  group('UpdateMemoryCover', () {
    test('calls repository and returns true', () async {
      // Arrange
      when(() => mockRepository.updateCover('memory-1', 'photo-1'))
          .thenAnswer((_) async => true);

      // Act
      final result = await sut.call('memory-1', 'photo-1');

      // Assert
      expect(result, isTrue);
      verify(() => mockRepository.updateCover('memory-1', 'photo-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.updateCover(any(), any()))
          .thenThrow(Exception('db'));

      // Act & Assert
      expect(() => sut.call('memory-1', 'photo-1'), throwsA(isA<Exception>()));
    });
  });
}
