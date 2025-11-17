import '../../domain/entities/group_memory_entity.dart';

/// DTO for converting Supabase JSON to GroupMemoryEntity
/// 
/// P2 Implementation Requirements:
/// - Parse all fields from Supabase JSON response
/// - Handle nullable fields gracefully with defaults
/// - Convert date strings to DateTime objects
class GroupMemoryModel {
  /// Convert Supabase JSON to GroupMemoryEntity
  /// 
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "id": "uuid",
  ///   "title": "Beach Day 2025",
  ///   "date": "2025-07-15T00:00:00Z",
  ///   "location": "Cascais Beach",      // nullable
  ///   "cover_photo_url": "https://...", // nullable
  ///   "photo_count": 24
  /// }
  /// ```
  static GroupMemoryEntity fromJson(Map<String, dynamic> json) {
    // P2 TODO: Implement JSON parsing
    // 
    // Implementation steps:
    // 1. Parse required fields (id, title, date, photo_count)
    // 2. Parse optional fields with null checks (location, cover_photo_url)
    // 3. Convert date string to DateTime using DateTime.parse()
    // 4. Return GroupMemoryEntity with all parsed data
    //
    // Example parsing:
    // return GroupMemoryEntity(
    //   id: json['id'] as String,
    //   title: json['title'] as String,
    //   date: DateTime.parse(json['date']),
    //   location: json['location'] as String?,
    //   coverPhotoUrl: json['cover_photo_url'] as String?,
    //   photoCount: json['photo_count'] as int,
    // );

    throw UnimplementedError('P2: Implement JSON to GroupMemoryEntity conversion');
  }
}
