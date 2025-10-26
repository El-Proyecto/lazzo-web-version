import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memory_repository.dart';

/// Fake implementation of MemoryRepository for P1 development
class FakeMemoryRepository implements MemoryRepository {
  static final _memories = <String, MemoryEntity>{
    'memory-1': MemoryEntity(
      id: 'memory-1',
      eventId: 'event-1',
      title: 'Beach Day',
      emoji: '🏖️',
      location: 'Marrakech, Morocco',
      eventDate: DateTime(2024, 7, 5),
      photos: [
        // Portrait photos
        MemoryPhoto(
          id: 'photo-1',
          url: 'https://picsum.photos/400/500',
          thumbnailUrl: 'https://picsum.photos/400/500',
          coverUrl: 'https://picsum.photos/800/1000',
          voteCount: 15,
          capturedAt: DateTime(2024, 7, 5, 14, 30),
          aspectRatio: 0.8, // 4:5
          uploaderId: 'user-1',
          uploaderName: 'Alice',
        ),
        MemoryPhoto(
          id: 'photo-2',
          url: 'https://picsum.photos/401/501',
          thumbnailUrl: 'https://picsum.photos/401/501',
          coverUrl: 'https://picsum.photos/801/1001',
          voteCount: 8,
          capturedAt: DateTime(2024, 7, 5, 15, 0),
          aspectRatio: 0.8,
          uploaderId: 'user-2',
          uploaderName: 'Bob',
        ),
        // Landscape photos
        MemoryPhoto(
          id: 'photo-3',
          url: 'https://picsum.photos/800/450',
          thumbnailUrl: 'https://picsum.photos/800/450',
          coverUrl: 'https://picsum.photos/1600/900',
          voteCount: 12,
          capturedAt: DateTime(2024, 7, 5, 16, 0),
          aspectRatio: 1.78, // 16:9
          uploaderId: 'user-1',
          uploaderName: 'Alice',
        ),
        MemoryPhoto(
          id: 'photo-4',
          url: 'https://picsum.photos/801/451',
          thumbnailUrl: 'https://picsum.photos/801/451',
          coverUrl: 'https://picsum.photos/1601/901',
          voteCount: 10,
          capturedAt: DateTime(2024, 7, 5, 16, 30),
          aspectRatio: 1.78,
          uploaderId: 'user-3',
          uploaderName: 'Charlie',
        ),
        // More grid photos
        MemoryPhoto(
          id: 'photo-5',
          url: 'https://picsum.photos/402/502',
          thumbnailUrl: 'https://picsum.photos/402/502',
          coverUrl: 'https://picsum.photos/802/1002',
          voteCount: 5,
          capturedAt: DateTime(2024, 7, 5, 17, 0),
          aspectRatio: 0.8,
          uploaderId: 'user-2',
          uploaderName: 'Bob',
        ),
        MemoryPhoto(
          id: 'photo-6',
          url: 'https://picsum.photos/802/452',
          thumbnailUrl: 'https://picsum.photos/802/452',
          coverUrl: 'https://picsum.photos/1602/902',
          voteCount: 7,
          capturedAt: DateTime(2024, 7, 5, 17, 30),
          aspectRatio: 1.78,
          uploaderId: 'user-1',
          uploaderName: 'Alice',
        ),
        MemoryPhoto(
          id: 'photo-7',
          url: 'https://picsum.photos/403/503',
          thumbnailUrl: 'https://picsum.photos/403/503',
          coverUrl: 'https://picsum.photos/803/1003',
          voteCount: 6,
          capturedAt: DateTime(2024, 7, 5, 18, 0),
          aspectRatio: 0.8,
          uploaderId: 'user-3',
          uploaderName: 'Charlie',
        ),
        MemoryPhoto(
          id: 'photo-8',
          url: 'https://picsum.photos/803/453',
          thumbnailUrl: 'https://picsum.photos/803/453',
          coverUrl: 'https://picsum.photos/1603/903',
          voteCount: 4,
          capturedAt: DateTime(2024, 7, 5, 18, 30),
          aspectRatio: 1.78,
          uploaderId: 'user-2',
          uploaderName: 'Bob',
        ),
      ],
    ),
  };

  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _memories[memoryId];
  }

  @override
  Future<MemoryEntity?> getMemoryByEventId(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _memories.values.firstWhere(
      (memory) => memory.eventId == eventId,
      orElse: () => _memories['memory-1']!,
    );
  }

  @override
  Future<String> shareMemory(String memoryId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    // Return mock share URL
    return 'https://lazzo.app/memory/$memoryId';
  }
}
