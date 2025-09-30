/// Permission settings for group creation
class GroupPermissions {
  final bool membersCanInvite;
  final bool membersCanAddPhotos;
  final bool membersCanCreateEvents;

  const GroupPermissions({
    this.membersCanInvite = false,
    this.membersCanAddPhotos = false,
    this.membersCanCreateEvents = false,
  });

  GroupPermissions copyWith({
    bool? membersCanInvite,
    bool? membersCanAddPhotos,
    bool? membersCanCreateEvents,
  }) {
    return GroupPermissions(
      membersCanInvite: membersCanInvite ?? this.membersCanInvite,
      membersCanAddPhotos: membersCanAddPhotos ?? this.membersCanAddPhotos,
      membersCanCreateEvents:
          membersCanCreateEvents ?? this.membersCanCreateEvents,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupPermissions &&
        other.membersCanInvite == membersCanInvite &&
        other.membersCanAddPhotos == membersCanAddPhotos &&
        other.membersCanCreateEvents == membersCanCreateEvents;
  }

  @override
  int get hashCode {
    return Object.hash(
      membersCanInvite,
      membersCanAddPhotos,
      membersCanCreateEvents,
    );
  }

  @override
  String toString() {
    return 'GroupPermissions(membersCanInvite: $membersCanInvite, membersCanAddPhotos: $membersCanAddPhotos, membersCanCreateEvents: $membersCanCreateEvents)';
  }
}
