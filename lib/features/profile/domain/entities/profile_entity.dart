import 'package:flutter/material.dart';
import '../../../../shared/themes/colors.dart';

/// Profile/User entity
/// Contains minimal fields needed by the profile UI
class ProfileEntity {
  final String id;
  final String name;
  final String? email;
  final String? profileImageUrl;
  final String? location;
  final DateTime? birthday;
  final List<MemoryEntity> memories;

  const ProfileEntity({
    required this.id,
    required this.name,
    this.email,
    this.profileImageUrl,
    this.location,
    this.birthday,
    this.memories = const [],
  });

  ProfileEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? location,
    DateTime? birthday,
    List<MemoryEntity>? memories,
    bool clearProfileImage = false,
    bool clearLocation = false,
    bool clearBirthday = false,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl:
          clearProfileImage ? null : (profileImageUrl ?? this.profileImageUrl),
      location: clearLocation ? null : (location ?? this.location),
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      memories: memories ?? this.memories,
    );
  }
}

/// Memory entity for profile memories section
class MemoryEntity {
  final String id;
  final String title;
  final String? coverImageUrl;
  final DateTime date;
  final String? location;
  final String? status; // Event status (living/recap/ended)

  const MemoryEntity({
    required this.id,
    required this.title,
    this.coverImageUrl,
    required this.date,
    this.location,
    this.status,
  });

  /// Whether memory is still in living state
  bool get isLiving => status == 'living';

  /// Whether memory is in recap state
  bool get isRecap => status == 'recap';

  /// Get border color for active memories (living/recap)
  Color? get activeBorderColor {
    if (isLiving) return BrandColors.living; // Purple
    if (isRecap) return BrandColors.recap; // Orange
    return null; // No border for ended memories
  }

  MemoryEntity copyWith({
    String? id,
    String? title,
    String? coverImageUrl,
    DateTime? date,
    String? location,
    String? status,
  }) {
    return MemoryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      date: date ?? this.date,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }
}
