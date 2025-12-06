import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import 'package:image_picker/image_picker.dart';

/// Fake implementation of ProfileRepository for development and testing
/// Returns mock data for profile operations
class FakeProfileRepository implements ProfileRepository {
  // Mock data for current user
  static final _currentUser = ProfileEntity(
    id: 'user_1',
    name: 'Mara Soares',
    email: 'mara.soares@example.com',
    profileImageUrl: 'https://picsum.photos/152/152?random=1',
    location: 'Buraca, Lisbon',
    birthday: DateTime(1995, 7, 15),
    memories: _mockMemories,
  );

  // Mock memories data
  static final _mockMemories = [
    MemoryEntity(
      id: 'memory_1',
      title: 'Jantar Casa João',
      coverImageUrl: 'https://picsum.photos/177/177?random=2',
      date: DateTime(2025, 12, 10),
      location: 'Bologna',
    ),
    MemoryEntity(
      id: 'memory_2',
      title: 'Saída em Roma',
      coverImageUrl: 'https://picsum.photos/177/177?random=3',
      date: DateTime(2024, 10, 8),
      location: 'Rome',
    ),
    MemoryEntity(
      id: 'memory_3',
      title: 'Gândara dos Olivais',
      coverImageUrl: 'https://picsum.photos/177/177?random=4',
      date: DateTime(2025, 2, 11),
      location: 'São Francisco do Conde, Bahia, Brasil',
    ),
    MemoryEntity(
      id: 'memory_4',
      title: 'Jamaica Bar Night Out with Friends',
      coverImageUrl: 'https://picsum.photos/177/177?random=5',
      date: DateTime(2025, 2, 11),
      location: 'Restaurante Muito Longo Nome, Lisboa',
    ),
  ];

  // Mock users data for other profiles
  static final _mockUsers = <String, ProfileEntity>{
    'user_2': ProfileEntity(
      id: 'user_2',
      name: 'João Silva',
      profileImageUrl: 'https://picsum.photos/152/152?random=6',
      location: 'Porto, Portugal',
      birthday: DateTime(1992, 3, 20),
      memories: [
        MemoryEntity(
          id: 'memory_5',
          title: 'Weekend in Porto',
          coverImageUrl: 'https://picsum.photos/177/177?random=7',
          date: DateTime(2024, 11, 15),
          location: 'Porto, Portugal',
        ),
      ],
    ),
  };

  @override
  Future<ProfileEntity> getCurrentUserProfile() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _currentUser;
  }

  @override
  Future<ProfileEntity> getProfileById(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (userId == _currentUser.id) {
      return _currentUser;
    }

    final user = _mockUsers[userId];
    if (user == null) {
      throw Exception('User not found with ID: $userId');
    }

    return user;
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // In a real implementation, this would save to the database
    // For now, just return the updated profile
    return profile;
  }

  @override
  Future<List<MemoryEntity>> getUserMemories(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (userId == _currentUser.id) {
      return _currentUser.memories;
    }

    final user = _mockUsers[userId];
    if (user == null) {
      throw Exception('User not found with ID: $userId');
    }

    return user.memories;
  }

  @override
  Future<String> uploadProfilePicture(XFile imageFile) async {
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return fake URL
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'https://picsum.photos/200/200?random=$timestamp';
  }

  @override
  Future<String?> getProfilePictureUrl(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    
    // Simulate async delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Return fake signed URL with cache busting
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'https://picsum.photos/200/200?random=$timestamp&path=$avatarUrl';
  }

  @override
  Future<void> deleteProfilePicture() async {
    // Simulate deletion delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a fake implementation, we just log the operation
      }
}
