/// Event history entity for event template reuse
/// Minimal fields needed to populate create event form
class EventHistory {
  final String id;
  final String name;
  final String emoji;
  final DateTime startDateTime;
  final String? locationId;
  final String? locationName; // Denormalized for performance
  final String? locationAddress; // Denormalized for performance
  final double? latitude; // Denormalized for performance
  final double? longitude; // Denormalized for performance
  final String groupId;
  final String? groupName; // Denormalized for performance
  final DateTime createdAt;

  const EventHistory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.startDateTime,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.groupId,
    this.groupName,
    required this.createdAt,
  });

  @override
  String toString() {
    return 'EventHistory(id: $id, name: $name, emoji: $emoji, startDateTime: $startDateTime, locationName: $locationName, groupId: $groupId, groupName: $groupName)';
  }
}
