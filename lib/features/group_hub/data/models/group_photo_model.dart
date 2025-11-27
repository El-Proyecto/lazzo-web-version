import '../../domain/entities/group_photo_entity.dart';

/// DTO/Model for converting Supabase JSON to GroupPhotoEntity
class GroupPhotoModel {
  final String id;
  final String url;
  final String storagePath;
  final DateTime capturedAt;
  final String uploaderId;
  final String? uploaderName;
  final bool isPortrait;

  const GroupPhotoModel({
    required this.id,
    required this.url,
    required this.storagePath,
    required this.capturedAt,
    required this.uploaderId,
    this.uploaderName,
    required this.isPortrait,
  });

  /// Parse from Supabase JSON response
  factory GroupPhotoModel.fromJson(Map<String, dynamic> json) {
    // Handle nested profiles join for uploader name
    String? uploaderName;
    final profiles = json['profiles'];
    if (profiles != null) {
      if (profiles is Map<String, dynamic>) {
        uploaderName = profiles['name'] as String?;
      } else if (profiles is List && profiles.isNotEmpty) {
        final firstProfile = profiles[0] as Map<String, dynamic>;
        uploaderName = firstProfile['name'] as String?;
      }
    }

    return GroupPhotoModel(
      id: json['id'] as String,
      url: json['url'] as String,
      storagePath: json['storage_path'] as String,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      uploaderId: json['uploader_id'] as String,
      uploaderName: uploaderName,
      isPortrait: json['is_portrait'] as bool? ?? false,
    );
  }

  /// Convert to domain entity
  GroupPhotoEntity toEntity() {
    return GroupPhotoEntity(
      id: id,
      url: url,
      capturedAt: capturedAt,
      uploaderId: uploaderId,
      uploaderName: uploaderName,
      isPortrait: isPortrait,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'storage_path': storagePath,
      'captured_at': capturedAt.toIso8601String(),
      'uploader_id': uploaderId,
      'is_portrait': isPortrait,
    };
  }

  GroupPhotoModel copyWith({
    String? id,
    String? url,
    String? storagePath,
    DateTime? capturedAt,
    String? uploaderId,
    String? uploaderName,
    bool? isPortrait,
  }) {
    return GroupPhotoModel(
      id: id ?? this.id,
      url: url ?? this.url,
      storagePath: storagePath ?? this.storagePath,
      capturedAt: capturedAt ?? this.capturedAt,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      isPortrait: isPortrait ?? this.isPortrait,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupPhotoModel &&
        other.id == id &&
        other.url == url &&
        other.storagePath == storagePath &&
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
      storagePath,
      capturedAt,
      uploaderId,
      uploaderName,
      isPortrait,
    );
  }

  @override
  String toString() {
    return 'GroupPhotoModel(id: $id, url: $url, capturedAt: $capturedAt, '
        'uploaderId: $uploaderId, uploaderName: $uploaderName, '
        'isPortrait: $isPortrait)';
  }
}
