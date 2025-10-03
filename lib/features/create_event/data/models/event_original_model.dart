import '../../domain/entities/event.dart';

class EventModel {
  final String id;
  final String name;
  final String emoji;
  final String groupId;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? locationId;
  final String status;
  final String createdBy;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.groupId,
    this.startDateTime,
    this.endDateTime,
    this.locationId,
    required this.status,
    required this.createdBy,
    required this.createdAt,
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
      groupId: json['group_id'] as String,
      startDateTime: asDateTime(json['start_datetime']),
      endDateTime: asDateTime(json['end_datetime']),
      locationId: json['location_id'] as String?,
      status: (json['status'] as String?)?.toLowerCase() ?? 'draft',
      createdBy: json['created_by'] as String,
      createdAt: asDateTime(json['created_at'])!,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'group_id': groupId,
      'start_datetime': startDateTime?.toIso8601String(),
      'end_datetime': endDateTime?.toIso8601String(),
      'location_id': locationId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Event toEntity({EventLocation? location}) {
    return Event(
      id: id,
      name: name,
      emoji: emoji,
      groupId: groupId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location,
      status: _parseEventStatus(status),
      createdAt: createdAt,
    );
  }

  factory EventModel.fromEntity(Event event, {required String createdBy}) {
    return EventModel(
      id: event.id,
      name: event.name,
      emoji: event.emoji,
      groupId: event.groupId,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      locationId: event.location?.id,
      status: event.status.toString().split('.').last,
      createdBy: createdBy,
      createdAt: event.createdAt,
    );
  }

  EventStatus _parseEventStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':     return EventStatus.pending;
      case 'confirmed': return EventStatus.confirmed;
      case 'ended': return EventStatus.ended;
      default:          return EventStatus.pending;
    }
  }
}
