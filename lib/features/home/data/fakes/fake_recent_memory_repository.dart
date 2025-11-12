import '../../domain/entities/recent_memory_entity.dart';
import '../../domain/repositories/recent_memory_repository.dart';

/// Fake implementation of RecentMemoryRepository for development
class FakeRecentMemoryRepository implements RecentMemoryRepository {
  @override
  Future<List<RecentMemoryEntity>> getRecentMemories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();

    // Create 5 memories within the last 30 days
    final memories = [
      RecentMemoryEntity(
        id: 'memory_1',
        eventName: 'Summer Beach Party',
        location: 'Cascais',
        date: now.subtract(const Duration(days: 3)),
        coverPhotoUrl: 'https://picsum.photos/seed/mem1/400/400',
      ),
      RecentMemoryEntity(
        id: 'memory_2',
        eventName: 'Night Out',
        location: 'Bairro Alto',
        date: now.subtract(const Duration(days: 8)),
        coverPhotoUrl: 'https://picsum.photos/seed/mem2/400/400',
      ),
      RecentMemoryEntity(
        id: 'memory_3',
        eventName: 'Birthday Celebration',
        location: 'LX Factory',
        date: now.subtract(const Duration(days: 15)),
        coverPhotoUrl: 'https://picsum.photos/seed/mem3/400/400',
      ),
      RecentMemoryEntity(
        id: 'memory_4',
        eventName: 'Concert Night',
        location: 'Altice Arena',
        date: now.subtract(const Duration(days: 20)),
        coverPhotoUrl: 'https://picsum.photos/seed/mem4/400/400',
      ),
      RecentMemoryEntity(
        id: 'memory_5',
        eventName: 'Brunch Vibes',
        location: 'Santos',
        date: now.subtract(const Duration(days: 27)),
        coverPhotoUrl: 'https://picsum.photos/seed/mem5/400/400',
      ),
    ];

    // Sort by date descending (most recent first)
    memories.sort((a, b) => b.date.compareTo(a.date));

    return memories;
  }
}
