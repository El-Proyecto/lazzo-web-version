import '../../domain/entities/event.dart';

class EventModel {
  final String id;
  final String name;
  final String emoji;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? locationId;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final String? description;

  EventModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.startDateTime,
    this.endDateTime,
    this.locationId,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.description,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime? asDateTime(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.toUtc();
      if (v is String && v.isNotEmpty) return DateTime.parse(v).toUtc();
      throw ArgumentError('Invalid date value: $v');
    }

    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: (json['emoji'] as String?) ?? '',
      startDateTime: asDateTime(json['start_datetime']),
      endDateTime: asDateTime(json['end_datetime']),
      locationId: json['location_id'] as String?,
      status: (json['status'] as String?)?.toLowerCase() ?? 'draft',
      createdBy: json['created_by'] as String,
      createdAt: asDateTime(json['created_at'])!,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'start_datetime': startDateTime?.toIso8601String(),
      'end_datetime': endDateTime?.toIso8601String(),
      'location_id': locationId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'description': description,
    };
  }

  Event toEntity({EventLocation? location}) {
    return Event(
      id: id,
      name: name,
      emoji: emoji,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location,
      status: _parseEventStatus(status),
      createdAt: createdAt,
      description: description,
    );
  }

  factory EventModel.fromEntity(Event event, {required String createdBy}) {
    return EventModel(
      id: event.id,
      name: event.name,
      emoji: event.emoji,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      locationId: event.location?.id,
      status: event.status.toString().split('.').last,
      createdBy: createdBy,
      createdAt: event.createdAt,
      description: event.description,
    );
  }

  EventStatus _parseEventStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return EventStatus.pending;
      case 'confirmed':
        return EventStatus.confirmed;
      case 'living':
        return EventStatus.living;
      case 'recap':
        return EventStatus.recap;
      case 'expired':
        return EventStatus.expired;
      default:
        return EventStatus.pending;
    }
  }
}
