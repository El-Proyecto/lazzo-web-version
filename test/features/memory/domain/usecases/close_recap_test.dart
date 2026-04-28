import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/domain/repositories/memory_repository.dart';
import 'package:lazzo/features/memory/domain/usecases/close_recap.dart';
import 'package:mocktail/mocktail.dart';

class MockMemoryRepository extends Mock implements MemoryRepository {}

void main() {
  late MockMemoryRepository mockRepository;
  late CloseRecap sut;

  setUp(() {
    mockRepository = MockMemoryRepository();
    sut = CloseRecap(mockRepository);
  });

  group('CloseRecap', () {
    test('calls repository and returns true', () async {
      // Arrange
      when(() => mockRepository.closeRecap('event-1')).thenAnswer((_) async => true);

      // Act
      final result = await sut.call('event-1');

      // Assert
      expect(result, isTrue);
      verify(() => mockRepository.closeRecap('event-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propagates repository exceptions', () {
      // Arrange
      when(() => mockRepository.closeRecap(any())).thenThrow(Exception('db'));

      // Act & Assert
      expect(() => sut.call('event-1'), throwsA(isA<Exception>()));
    });
  });
}
