import '../../domain/entities/group_memory_entity.dart';

/// DTO for converting Supabase JSON to GroupMemoryEntity
/// 
/// P2 Implementation Requirements:
/// - Parse all fields from Supabase JSON response
/// - Handle nullable fields gracefully with defaults
/// - Convert date strings to DateTime objects
/// - Extract cover photo storage_path for signed URL generation
class GroupMemoryModel {
  /// Convert Supabase JSON to GroupMemoryEntity
  /// 
  /// Expected JSON structure from query with JOIN:
  /// ```json
  /// {
  ///   "id": "uuid",
  ///   "name": "Beach Day 2025",
  ///   "start_datetime": "2025-07-15T14:00:00Z",
  ///   "emoji": "🏖️",
  ///   "status": "recap",
  ///   "cover_photo_id": "photo-uuid",
  ///   "locations": {
  ///     "display_name": "Cascais Beach"
  ///   },
  ///   "group_photos": {
  ///     "storage_path": "groupId/eventId/userId/uuid.jpg"
  ///   }
  /// }
  /// ```
  static GroupMemoryEntity fromJson(Map<String, dynamic> json) {
    // Parse location from nested object
    final locationData = json['locations'];
    final locationName = locationData != null 
        ? locationData['display_name'] as String? 
        : null;

    // Parse date
    final dateStr = json['start_datetime'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    // Extract cover photo storage_path (already processed by data source with fallback)
    final coverStoragePath = json['cover_storage_path'] as String?;
    
    // Extract photo count
    final photoCount = json['photo_count'] as int? ?? 0;

    return GroupMemoryEntity(
      id: json['id'] as String,
      title: json['name'] as String? ?? 'Untitled Memory',
      date: date,
      location: locationName,
      coverImageUrl: coverStoragePath ?? '', // Storage path (repository will generate signed URL)
      photoCount: photoCount,
    );
  }
}
