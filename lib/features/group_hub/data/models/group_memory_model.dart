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
    // Parse location from nested object
    final locationData = json['locations'];
    final locationName = locationData != null ? locationData['name'] as String? : null;

    // Parse date
    final dateStr = json['start_datetime'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    return GroupMemoryEntity(
      id: json['id'] as String,
      title: json['name'] as String? ?? 'Untitled Memory',
      date: date,
      location: locationName,
      coverImageUrl: '', // TODO: Get from photos when implemented
      photoCount: 0, // TODO: Count from group_photos when implemented
    );
  }
}
