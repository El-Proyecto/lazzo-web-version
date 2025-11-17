// DTO models for Poll - maps Supabase JSON to/from domain entities

import '../../domain/entities/poll.dart';

/// Poll DTO Model
class PollModel {
  final String id;
  final String eventId;
  final String type;
  final String question;
  final DateTime createdAt;
  final String createdBy;
  final List<PollOptionModel> options;

  const PollModel({
    required this.id,
    required this.eventId,
    required this.type,
    required this.question,
    required this.createdAt,
    required this.createdBy,
    required this.options,
  });

  /// Create model from Supabase JSON
  factory PollModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>? ?? [];
    final options = optionsJson
        .map((opt) => PollOptionModel.fromJson(opt as Map<String, dynamic>))
        .toList();

    return PollModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      type: json['type'] as String? ?? 'custom',
      question: json['question'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
      options: options,
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'type': type,
      'question': question,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  /// Convert to domain entity
  Poll toEntity() {
    // Parse type enum
    PollType typeEnum;
    switch (type.toLowerCase()) {
      case 'date':
        typeEnum = PollType.date;
        break;
      case 'location':
        typeEnum = PollType.location;
        break;
      default:
        typeEnum = PollType.custom;
    }

    // Convert options to entities (empty votedUserIds for now)
    final entityOptions = options.map((opt) => opt.toEntity([])).toList();

    return Poll(
      id: id,
      eventId: eventId,
      type: typeEnum,
      question: question,
      options: entityOptions,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  /// Create model from domain entity
  factory PollModel.fromEntity(Poll entity) {
    // Convert poll options to models
    final optionModels = entity.options
        .map((opt) => PollOptionModel.fromEntity(opt))
        .toList();

    return PollModel(
      id: entity.id,
      eventId: entity.eventId,
      type: entity.type.name,
      question: entity.question,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      options: optionModels,
    );
  }
}

/// Poll Option DTO Model
class PollOptionModel {
  final String id;
  final String pollId;
  final String value;
  final int voteCount;

  const PollOptionModel({
    required this.id,
    required this.pollId,
    required this.value,
    required this.voteCount,
  });

  /// Create model from Supabase JSON
  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      value: json['value'] as String,
      voteCount: json['vote_count'] as int? ?? 0,
    );
  }

  /// Convert model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'value': value,
      'vote_count': voteCount,
    };
  }

  /// Convert to domain entity (requires voted user IDs)
  PollOption toEntity(List<String> votedUserIds) {
    return PollOption(
      id: id,
      pollId: pollId,
      value: value,
      voteCount: voteCount,
      votedUserIds: votedUserIds,
    );
  }

  /// Create model from domain entity
  factory PollOptionModel.fromEntity(PollOption entity) {
    return PollOptionModel(
      id: entity.id,
      pollId: entity.pollId,
      value: entity.value,
      voteCount: entity.voteCount,
    );
  }
}
