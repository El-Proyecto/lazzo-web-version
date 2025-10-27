import '../../domain/entities/group_memory_entity.dart';
import '../../domain/repositories/group_memory_repository.dart';

/// Fake implementation of GroupMemoryRepository for development
class FakeGroupMemoryRepository implements GroupMemoryRepository {
  final List<GroupMemoryEntity> _memories = [
    GroupMemoryEntity(
      id: 'memory_1',
      title: 'Beach Day Vibes',
      location: 'Cascais',
      date: DateTime(2025, 10, 15),
      coverImageUrl: 'https://picsum.photos/300/300?random=101',
      photoCount: 24,
    ),
    GroupMemoryEntity(
      id: 'memory_2',
      title: 'BBQ Night',
      location: 'Marco\'s House',
      date: DateTime(2025, 10, 8),
      coverImageUrl: 'https://picsum.photos/300/300?random=102',
      photoCount: 18,
    ),
    GroupMemoryEntity(
      id: 'memory_3',
      title: 'Concert Madness',
      location: 'Altice Arena',
      date: DateTime(2025, 9, 22),
      coverImageUrl: 'https://picsum.photos/300/300?random=103',
      photoCount: 45,
    ),
    GroupMemoryEntity(
      id: 'memory_4',
      title: 'Road Trip',
      location: 'Porto',
      date: DateTime(2025, 9, 10),
      coverImageUrl: 'https://picsum.photos/300/300?random=104',
      photoCount: 67,
    ),
    GroupMemoryEntity(
      id: 'memory_5',
      title: 'Birthday Celebration',
      location: 'Ana\'s Place',
      date: DateTime(2025, 8, 28),
      coverImageUrl: 'https://picsum.photos/300/300?random=105',
      photoCount: 32,
    ),
    GroupMemoryEntity(
      id: 'memory_6',
      title: 'Weekend Getaway',
      location: 'Óbidos',
      date: DateTime(2025, 8, 14),
      coverImageUrl: 'https://picsum.photos/300/300?random=106',
      photoCount: 28,
    ),
    GroupMemoryEntity(
      id: 'memory_7',
      title: 'Game Night',
      location: 'João\'s Apartment',
      date: DateTime(2025, 7, 30),
      coverImageUrl: 'https://picsum.photos/300/300?random=107',
      photoCount: 15,
    ),
  ];

  @override
  Future<List<GroupMemoryEntity>> getGroupMemories(String groupId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Return all memories for any group (mock data)
    return _memories;
  }

  @override
  Future<GroupMemoryEntity?> getMemoryById(String memoryId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _memories.firstWhere((memory) => memory.id == memoryId);
    } catch (e) {
      return null;
    }
  }
}
