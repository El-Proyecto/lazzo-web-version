import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/domain/repositories/memory_repository.dart';
import 'package:lazzo/features/memory/domain/usecases/share_memory.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoryRepository extends Mock implements MemoryRepository {}

void main() {
  late MockMemoryRepository mockRepository;
  late ShareMemory sut;

  setUp(() {
    mockRepository = MockMemoryRepository();
    sut = ShareMemory(mockRepository);
  });

  group('ShareMemory', () {
    test('calls repository and returns share link', () async {
      // Arrange
      when(() => mockRepository.shareMemory('memory-1'))
          .thenAnswer((_) async => 'https://share');

      // Act
      final result = await sut.call('memory-1');

      // Assert
      expect(result, 'https://share');
      verify(() => mockRepository.shareMemory('memory-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.shareMemory(any())).thenThrow(Exception('db'));

      // Act & Assert
      expect(() => sut.call('memory-1'), throwsA(isA<Exception>()));
    });
  });
}
