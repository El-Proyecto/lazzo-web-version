import 'group_permissions.dart';

/// Group entity representing a group in the domain layer
class GroupEntity {
  final String? id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String? qrCode;
  final String? groupUrl;
  final GroupPermissions permissions;
  final DateTime? createdAt;

  const GroupEntity({
    this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.qrCode,
    this.groupUrl,
    required this.permissions,
    this.createdAt,
  });

  GroupEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? photoUrl,
    String? qrCode,
    String? groupUrl,
    GroupPermissions? permissions,
    DateTime? createdAt,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      qrCode: qrCode ?? this.qrCode,
      groupUrl: groupUrl ?? this.groupUrl,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupEntity &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.photoUrl == photoUrl &&
        other.qrCode == qrCode &&
        other.groupUrl == groupUrl &&
        other.permissions == permissions &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, description, photoUrl, qrCode, groupUrl, permissions, createdAt);
  }

  @override
  String toString() {
    return 'GroupEntity(id: $id, name: $name, description: $description, photoUrl: $photoUrl, qrCode: $qrCode, groupUrl: $groupUrl, permissions: $permissions, createdAt: $createdAt)';
  }
}
