/// Group photo entity
/// Represents a photo within a group memory/event
class GroupPhotoEntity {
  final String id;
  final String url;
  final DateTime capturedAt;
  final String? uploaderId;
  final String? uploaderName;
  final bool isPortrait;

  const GroupPhotoEntity({
    required this.id,
    required this.url,
    required this.capturedAt,
    this.uploaderId,
    this.uploaderName,
    required this.isPortrait,
  });

  GroupPhotoEntity copyWith({
    String? id,
    String? url,
    DateTime? capturedAt,
    String? uploaderId,
    String? uploaderName,
    bool? isPortrait,
  }) {
    return GroupPhotoEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      capturedAt: capturedAt ?? this.capturedAt,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      isPortrait: isPortrait ?? this.isPortrait,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupPhotoEntity &&
        other.id == id &&
        other.url == url &&
        other.capturedAt == capturedAt &&
        other.uploaderId == uploaderId &&
        other.uploaderName == uploaderName &&
        other.isPortrait == isPortrait;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      url,
      capturedAt,
      uploaderId,
      uploaderName,
      isPortrait,
    );
  }
}
