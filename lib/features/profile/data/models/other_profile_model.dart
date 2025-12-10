import '../../../group_hub/domain/entities/group_event_entity.dart';
import '../../domain/entities/other_profile_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/shared_memory_entity.dart';

/// DTO for other user profile data from Supabase
class OtherProfileModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? city;
  final DateTime? birthDate;

  OtherProfileModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.city,
    this.birthDate,
  });

  /// Parse from Supabase users table row
  factory OtherProfileModel.fromMap(Map<String, dynamic> map) {
    return OtherProfileModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      avatarUrl: map['avatar_url'] as String?,
      city: map['city'] as String?,
      birthDate: map['birth_date'] != null 
          ? DateTime.tryParse(map['birth_date'] as String)
          : null,
    );
  }

  /// Convert to domain entity
  /// Note: memoriesTogether and upcomingTogether lists are set by repository
  OtherProfileEntity toEntity({
    String? signedAvatarUrl,
    List<MemoryEntity> memoriesTogether = const [],
    List<GroupEventEntity> upcomingTogether = const [],
  }) {
    return OtherProfileEntity(
      id: id,
      name: name,
      profileImageUrl: signedAvatarUrl, // Use signed URL from repository
      location: city,
      birthday: birthDate,
      memoriesTogether: memoriesTogether,
      upcomingTogether: upcomingTogether,
    );
  }
}

/// DTO for shared memory (event) data from Supabase
class SharedMemoryModel {
  final String id;
  final String title;
  final String? emoji;
  final DateTime? date;
  final String? location;
  final String? coverStoragePath;

  SharedMemoryModel({
    required this.id,
    required this.title,
    this.emoji,
    this.date,
    this.location,
    this.coverStoragePath,
  });

  /// Parse from Supabase events query with joined tables
  factory SharedMemoryModel.fromMap(Map<String, dynamic> map) {
    return SharedMemoryModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? map['name'] as String? ?? 'Untitled Event',
      emoji: map['emoji'] as String?,
      date: map['date'] != null 
          ? DateTime.tryParse(map['date'] as String)
          : map['end_datetime'] != null
              ? DateTime.tryParse(map['end_datetime'] as String)
              : null,
      location: map['location'] as String?,
      coverStoragePath: map['cover_storage_path'] as String?,
    );
  }

  /// Convert to domain entity
  /// signedCoverUrl is provided by repository after generating signed URL
  SharedMemoryEntity toEntity({String? signedCoverUrl}) {
    return SharedMemoryEntity(
      id: id,
      title: title,
      emoji: emoji,
      date: date,
      location: location,
      coverPhotoUrl: signedCoverUrl,
    );
  }
}
