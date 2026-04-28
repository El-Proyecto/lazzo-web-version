import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/repositories/event_photo_repository.dart';
import 'package:lazzo/features/event/domain/usecases/upload_event_photo.dart';
import 'package:mocktail/mocktail.dart';

class MockEventPhotoRepository extends Mock implements EventPhotoRepository {}

void main() {
  late MockEventPhotoRepository mockRepository;
  late UploadEventPhoto sut;

  setUp(() {
    mockRepository = MockEventPhotoRepository();
    sut = UploadEventPhoto(mockRepository);
  });

  group('UploadEventPhoto', () {
    test('throws ArgumentError when eventId is empty', () {
      // Act & Assert
      expect(
        () => sut.call(eventId: '', imageFile: File('missing.jpg')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when image file does not exist', () {
      // Act & Assert
      expect(
        () => sut.call(eventId: 'event-1', imageFile: File('missing.jpg')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('calls repository.uploadPhoto with valid inputs', () async {
      // Arrange
      final tempDir = await Directory.systemTemp.createTemp('upload_photo_test');
      final imageFile = File('${tempDir.path}/image.jpg');
      await imageFile.writeAsString('image-bytes');
      when(
        () => mockRepository.uploadPhoto(
          eventId: 'event-1',
          imageFile: imageFile,
          capturedAt: any(named: 'capturedAt'),
        ),
      ).thenAnswer((_) async => 'https://cdn/image.jpg');

      // Act
      final result = await sut.call(eventId: 'event-1', imageFile: imageFile);

      // Assert
      expect(result, 'https://cdn/image.jpg');
      verify(
        () => mockRepository.uploadPhoto(
          eventId: 'event-1',
          imageFile: imageFile,
          capturedAt: any(named: 'capturedAt'),
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);

      await tempDir.delete(recursive: true);
    });
  });
}
