/// Recent memory entity representing a memory from the last 30 days
class RecentMemoryEntity {
  final String id;
  final String eventName;
  final String? location;
  final DateTime date;
  final String? coverPhotoUrl;

  const RecentMemoryEntity({
    required this.id,
    required this.eventName,
    this.location,
    required this.date,
    this.coverPhotoUrl,
  });

  /// Formatted date for display (e.g., "12 Jul")
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final day = date.day;
    final month = months[date.month - 1];

    return '$day $month';
  }

  /// Location and date formatted for display (e.g., "Bairro Alto • 12 Jul")
  String get locationDateText {
    if (location != null && location!.isNotEmpty) {
      return '$location • $formattedDate';
    }
    return formattedDate;
  }

  RecentMemoryEntity copyWith({
    String? id,
    String? eventName,
    String? location,
    DateTime? date,
    String? coverPhotoUrl,
  }) {
    return RecentMemoryEntity(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      location: location ?? this.location,
      date: date ?? this.date,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
    );
  }
}
