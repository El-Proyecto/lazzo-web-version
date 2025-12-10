/// Model for recent memory data from Supabase
class RecentMemoryModel {
  final String id;
  final String eventName;
  final String? location;
  final DateTime date;
  final String? coverStoragePath;

  RecentMemoryModel({
    required this.id,
    required this.eventName,
    this.location,
    required this.date,
    this.coverStoragePath,
  });

  /// Create model from Supabase JSON response
  factory RecentMemoryModel.fromJson(Map<String, dynamic> json) {
    // Extract location from nested locations object
    String? location;
    final locationsData = json['locations'];
    if (locationsData != null && locationsData is Map<String, dynamic>) {
      location = locationsData['display_name'] as String?;
    }

    // Use end_datetime for the memory date (when event ended)
    final endDateStr = json['end_datetime'] as String?;
    final date = endDateStr != null 
        ? DateTime.parse(endDateStr)
        : DateTime.parse(json['start_datetime'] as String);

    return RecentMemoryModel(
      id: json['id'] as String,
      eventName: json['name'] as String,
      location: location,
      date: date,
      coverStoragePath: json['cover_storage_path'] as String?,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': eventName,
      'location': location,
      'end_datetime': date.toIso8601String(),
      'cover_storage_path': coverStoragePath,
    };
  }
}
