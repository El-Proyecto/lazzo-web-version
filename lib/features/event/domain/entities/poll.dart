/// Poll domain entity
/// Represents a poll for event details (date/location)
class Poll {
  final String id;
  final String eventId;
  final PollType type;
  final String question;
  final List<PollOption> options;
  final DateTime createdAt;
  final String createdBy;

  const Poll({
    required this.id,
    required this.eventId,
    required this.type,
    required this.question,
    required this.options,
    required this.createdAt,
    required this.createdBy,
  });

  Poll copyWith({
    String? id,
    String? eventId,
    PollType? type,
    String? question,
    List<PollOption>? options,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Poll(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      question: question ?? this.question,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Poll option domain entity
class PollOption {
  final String id;
  final String pollId;
  final String value;
  final int voteCount;
  final List<String> votedUserIds;

  const PollOption({
    required this.id,
    required this.pollId,
    required this.value,
    required this.voteCount,
    required this.votedUserIds,
  });

  PollOption copyWith({
    String? id,
    String? pollId,
    String? value,
    int? voteCount,
    List<String>? votedUserIds,
  }) {
    return PollOption(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      value: value ?? this.value,
      voteCount: voteCount ?? this.voteCount,
      votedUserIds: votedUserIds ?? this.votedUserIds,
    );
  }
}

/// Poll type enumeration
enum PollType { date, location, custom }
