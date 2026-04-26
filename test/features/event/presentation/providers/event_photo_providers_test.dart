import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/event/domain/repositories/event_photo_repository.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart';
import 'package:lazzo/features/event/presentation/providers/event_photo_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockEventPhotoRepository extends Mock implements EventPhotoRepository {}

void main() {
  late MockEventPhotoRepository mockEventPhotoRepository;

  setUp(() {
    mockEventPhotoRepository = MockEventPhotoRepository();
  });

  group('eventPhotosProvider', () {
    test('returns photo list on success', () async {
      final photos = [
        {'id': 'photo-1', 'url': 'https://example.test/photo-1.jpg'},
      ];
      when(() => mockEventPhotoRepository.getEventPhotos('event-1'))
          .thenAnswer((_) async => photos);

      final container = ProviderContainer(
        overrides: [
          eventPhotoRepositoryProvider.overrideWithValue(mockEventPhotoRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(eventPhotosProvider('event-1').future);

      expect(result, photos);
      verify(() => mockEventPhotoRepository.getEventPhotos('event-1')).called(1);
      verifyNoMoreInteractions(mockEventPhotoRepository);
    });

    test('throws when repository fails', () async {
      when(() => mockEventPhotoRepository.getEventPhotos(any()))
          .thenThrow(Exception('photo-fail'));

      final container = ProviderContainer(
        overrides: [
          eventPhotoRepositoryProvider.overrideWithValue(mockEventPhotoRepository),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(eventPhotosProvider('event-1').future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
