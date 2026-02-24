import '../../domain/entities/calendar_event_entity.dart';

/// DTO for calendar event - converts Supabase rows to CalendarEventEntity
class CalendarEventModel {
  final String id;
  final String name;
  final String emoji;
  final DateTime? date;
  final DateTime? endDate;
  final String? location;
  final String status;
  final String? coverPhotoStoragePath;

  const CalendarEventModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.date,
    this.endDate,
    this.location,
    required this.status,
    this.coverPhotoStoragePath,
  });

  factory CalendarEventModel.fromMap(Map<String, dynamic> map) {
    return CalendarEventModel(
      id: (map['event_id'] ?? map['id'] ?? '') as String,
      name: (map['event_name'] ?? map['name'] ?? '') as String,
      emoji: _normalizeEmoji((map['emoji'] ?? '📅') as String),
      date: _parseDateTime(map['start_datetime']),
      endDate: _parseDateTime(map['end_datetime']),
      location: (map['location_name'] as String?) ??
          ((map['locations'] as Map<String, dynamic>?)?['display_name']
              as String?),
      status: _calculateStatus(
        (map['event_status'] ?? map['status'] ?? 'pending') as String,
        _parseDateTime(map['start_datetime']),
        _parseDateTime(map['end_datetime']),
      ),
      coverPhotoStoragePath: map['cover_storage_path'] as String?,
    );
  }

  CalendarEventEntity toEntity({String? coverPhotoUrl}) {
    return CalendarEventEntity(
      id: id,
      name: name,
      emoji: emoji,
      date: date,
      endDate: endDate,
      location: location,
      status: _mapStatus(status),
      coverPhotoUrl: coverPhotoUrl,
    );
  }

  static CalendarEventStatus _mapStatus(String status) {
    switch (status) {
      case 'confirmed':
        return CalendarEventStatus.confirmed;
      case 'living':
        return CalendarEventStatus.living;
      case 'recap':
        return CalendarEventStatus.recap;
      case 'ended':
        return CalendarEventStatus.ended;
      case 'pending':
      default:
        return CalendarEventStatus.pending;
    }
  }

  static String _calculateStatus(
      String backendStatus, DateTime? startDate, DateTime? endDate) {
    final now = DateTime.now().toUtc();
    const recapDuration = Duration(hours: 24);

    // Pending events never auto-transition
    if (backendStatus == 'pending') {
      return backendStatus;
    }

    if (backendStatus == 'confirmed' &&
        startDate != null &&
        startDate.toUtc().isBefore(now)) {
      // Event has started
      if (endDate == null || endDate.toUtc().isAfter(now)) {
        return 'living';
      }
      // Event has ended
      if (now.toUtc().difference(endDate.toUtc()) < recapDuration) {
        return 'recap';
      }
      // Past recap period → ended
      return 'ended';
    }

    return backendStatus;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _normalizeEmoji(String raw) {
    if (raw.isEmpty) return '📅';
    // Remove wrapping quotes if present
    String cleaned = raw;
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.isEmpty ? '📅' : cleaned;
  }
}
