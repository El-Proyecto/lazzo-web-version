/// Domain entity for date/time suggestions
class Suggestion {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final DateTime createdAt;

  const Suggestion({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.startDateTime,
    this.endDateTime,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Domain entity for location suggestions
class LocationSuggestion {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const LocationSuggestion({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSuggestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Domain entity for suggestion votes
class SuggestionVote {
  final String id;
  final String suggestionId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  const SuggestionVote({
    required this.id,
    required this.suggestionId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionVote &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
