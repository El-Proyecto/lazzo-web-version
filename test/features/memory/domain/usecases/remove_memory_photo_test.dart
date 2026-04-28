import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/domain/repositories/memory_repository.dart';
import 'package:lazzo/features/memory/domain/usecases/remove_memory_photo.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoryRepository extends Mock implements MemoryRepository {}

void main() {
  late MockMemoryRepository mockRepository;
  late RemoveMemoryPhoto sut;

  setUp(() {
    mockRepository = MockMemoryRepository();
    sut = RemoveMemoryPhoto(mockRepository);
  });

  group('RemoveMemoryPhoto', () {
    test('calls repository and returns true', () async {
      // Arrange
      when(() => mockRepository.removePhoto('memory-1', 'photo-1'))
          .thenAnswer((_) async => true);

      // Act
      final result = await sut.call('memory-1', 'photo-1');

      // Assert
      expect(result, isTrue);
      verify(() => mockRepository.removePhoto('memory-1', 'photo-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.removePhoto(any(), any()))
          .thenThrow(Exception('db'));

      // Act & Assert
      expect(() => sut.call('memory-1', 'photo-1'), throwsA(isA<Exception>()));
    });
  });
}
