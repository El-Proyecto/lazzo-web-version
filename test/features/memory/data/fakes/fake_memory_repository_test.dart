import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/memory/data/fakes/fake_memory_repository.dart';
import 'package:lazzo/features/memory/domain/entities/memory_entity.dart';
import 'package:lazzo/features/memory/domain/repositories/memory_repository.dart';

void main() {
  // ignore: unused_local_variable
  final MemoryRepository _ = FakeMemoryRepository();

  late FakeMemoryRepository repo;

  setUp(() {
    repo = FakeMemoryRepository();
    FakeMemoryConfig.coverPortraitCount = 2;
    FakeMemoryConfig.coverLandscapeCount = 1;
    FakeMemoryConfig.gridPortraitCount = 1;
    FakeMemoryConfig.gridLandscapeCount = 1;
    FakeMemoryConfig.eventStatus = FakeEventStatus.recap;
    FakeMemoryConfig.closeTime =
        DateTime.now().add(const Duration(hours: 2, minutes: 30));
  });

  group('FakeMemoryRepository', () {
    test('getMemoryByEventId returns typed entity', () async {
      final memory = await repo.getMemoryByEventId('event-1');

      expect(memory, isA<MemoryEntity>());
      expect(memory, isNotNull);
      expect(memory!.photos, isNotEmpty);
    });

    test('shareMemory returns non-empty URL', () async {
      final shareUrl = await repo.shareMemory('memory-1');

      expect(shareUrl, isNotEmpty);
      expect(shareUrl, startsWith('https://'));
    });

    test('updateCover returns success', () async {
      final result = await repo.updateCover('memory-1', 'photo-1');
      expect(result, isTrue);
    });

    test('removePhoto returns success', () async {
      final result = await repo.removePhoto('memory-1', 'photo-1');
      expect(result, isTrue);
    });
  });
}
