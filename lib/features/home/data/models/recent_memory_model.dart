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
    // Extract location - supports both nested object and direct field (from RPC)
    String? location;
    final locationsData = json['locations'];
    if (locationsData != null && locationsData is Map<String, dynamic>) {
      // Nested object format (from regular query)
      location = locationsData['display_name'] as String?;
    } else if (json['display_name'] != null) {
      // Direct field format (from RPC function)
      location = json['display_name'] as String?;
    }

    // Parse date safely - handle null and different formats
    DateTime date;
    final endDatetimeValue = json['end_datetime'];
    final startDatetimeValue = json['start_datetime'];

    if (endDatetimeValue != null) {
      if (endDatetimeValue is String) {
        date = DateTime.tryParse(endDatetimeValue) ?? DateTime.now();
      } else if (endDatetimeValue is DateTime) {
        date = endDatetimeValue;
      } else {
        date = DateTime.now();
      }
    } else if (startDatetimeValue != null) {
      if (startDatetimeValue is String) {
        date = DateTime.tryParse(startDatetimeValue) ?? DateTime.now();
      } else if (startDatetimeValue is DateTime) {
        date = startDatetimeValue;
      } else {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

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
