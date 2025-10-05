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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
    'city': city,
    'birth_date': birthDate?.toIso8601String(),
  };

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

// DTO memory model for profile memories
class MemoryModel {
  final String eventId;
  final String title;
  final String? imageUrl;
  final DateTime createdAt;
  final String? location;

  const MemoryModel({
    required this.eventId,
    required this.title,
    this.imageUrl,
    required this.createdAt,
    this.location,
  });

  factory MemoryModel.fromMap(Map<String, dynamic> row) => MemoryModel(
    eventId: row['mem_id'] as String,
    title: row['mem_title'] as String,
    imageUrl: row['photo_id'] as String?,
    createdAt: DateTime.parse(row['mem_date'] as String),
    location: row['mem_location'] as String?,
  );

  MemoryEntity toEntity() => MemoryEntity(
    id: eventId,
    title: title,
    coverImageUrl: imageUrl,
    date: createdAt,
    location: location,
  );
}
