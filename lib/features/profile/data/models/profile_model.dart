// DTO profile model

import '../../domain/entities/profile_entity.dart';

class ProfileModel {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? city;
  final DateTime? birthDate;

  const ProfileModel({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.city,
    this.birthDate,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> row) => ProfileModel(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        city: row['city'] as String?,
        birthDate: row['birth_date'] != null
            ? DateTime.parse(row['birth_date'] as String)
            : null,
      );

  Map<String, dynamic> toMap() {
    // Extract storage path from URL if it's a public URL
    String? storagePathOnly;
    if (avatarUrl != null) {
      final url = avatarUrl!;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // Extract path after '/object/public/users-profile-pic/'
        final match =
            RegExp(r'/object/public/users-profile-pic/(.+)$').firstMatch(url);
        if (match != null) {
          storagePathOnly = match.group(1);
        } else {
          storagePathOnly = avatarUrl;
        }
      } else {
        storagePathOnly = avatarUrl;
      }
    }

    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': storagePathOnly,
      'city': city,
      'birth_date': birthDate?.toIso8601String(),
    };
  }

  ProfileEntity toEntity({List<MemoryEntity> memories = const []}) =>
      ProfileEntity(
        id: id,
        name: name,
        email: email,
        profileImageUrl: avatarUrl,
        location: city,
        birthday: birthDate,
        memories: memories,
      );

  factory ProfileModel.fromEntity(ProfileEntity entity) => ProfileModel(
        id: entity.id,
        name: entity.name,
        email: entity.email,
        avatarUrl: entity.profileImageUrl,
        city: entity.location,
        birthDate: entity.birthday,
      );
}

// DTO memory model for profile memories (events with status recap/ended)
class MemoryModel {
  final String eventId;
  final String title;
  final String? coverStoragePath;
  final DateTime date;
  final String? location;
  final String? status; // Event status (living/recap/ended)

  const MemoryModel({
    required this.eventId,
    required this.title,
    this.coverStoragePath,
    required this.date,
    this.location,
    this.status,
  });

  factory MemoryModel.fromMap(Map<String, dynamic> row) {
    // Extract location - supports both nested object and direct field (from RPC)
    String? locationName;
    if (row['locations'] != null) {
      // Nested object format (from regular query)
      final locations = row['locations'];
      locationName = locations['display_name'] as String?;
    } else if (row['display_name'] != null) {
      // Direct field format (from RPC function)
      locationName = row['display_name'] as String?;
    }

    // Parse date safely - handle null values
    DateTime? parsedDate;
    final endDatetimeValue = row['end_datetime'];
    if (endDatetimeValue != null) {
      if (endDatetimeValue is String) {
        parsedDate = DateTime.tryParse(endDatetimeValue);
      } else if (endDatetimeValue is DateTime) {
        parsedDate = endDatetimeValue;
      }
    }

    return MemoryModel(
      eventId: row['id'] as String,
      title: row['name'] as String,
      coverStoragePath: row['cover_storage_path'] as String?,
      date: parsedDate ?? DateTime.now(), // Fallback to now if null
      location: locationName,
      status: row['status'] as String?, // Event status from RPC
    );
  }

  MemoryEntity toEntity({String? signedUrl}) => MemoryEntity(
        id: eventId,
        title: title,
        coverImageUrl: signedUrl,
        date: date,
        location: location,
        status: status,
      );
}
