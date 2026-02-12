import 'profile_entity.dart';
import '../../../event/domain/entities/event_display_entity.dart';

/// Other user's profile entity
/// Contains profile information plus shared context (events and memories)
class OtherProfileEntity {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String? location;
  final DateTime? birthday;
  final List<EventDisplayEntity> upcomingTogether;
  final List<MemoryEntity> memoriesTogether;

  const OtherProfileEntity({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.location,
    this.birthday,
    this.upcomingTogether = const [],
    this.memoriesTogether = const [],
  });

  OtherProfileEntity copyWith({
    String? id,
    String? name,
    String? profileImageUrl,
    String? location,
    DateTime? birthday,
    List<EventDisplayEntity>? upcomingTogether,
    List<MemoryEntity>? memoriesTogether,
    bool clearProfileImage = false,
    bool clearLocation = false,
    bool clearBirthday = false,
  }) {
    return OtherProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl:
          clearProfileImage ? null : (profileImageUrl ?? this.profileImageUrl),
      location: clearLocation ? null : (location ?? this.location),
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      upcomingTogether: upcomingTogether ?? this.upcomingTogether,
      memoriesTogether: memoriesTogether ?? this.memoriesTogether,
    );
  }
}
