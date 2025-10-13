/// Permission settings for group creation
class GroupPermissions {
  final bool membersCanInvite;
  final bool membersCanAddMembers;
  final bool membersCanCreateEvents;

  const GroupPermissions({
    this.membersCanInvite = false,
    this.membersCanAddMembers = false,
    this.membersCanCreateEvents = false,
  });

  GroupPermissions copyWith({
    bool? membersCanInvite,
    bool? membersCanAddMembers,
    bool? membersCanCreateEvents,
  }) {
    return GroupPermissions(
      membersCanInvite: membersCanInvite ?? this.membersCanInvite,
      membersCanAddMembers: membersCanAddMembers ?? this.membersCanAddMembers,
      membersCanCreateEvents:
          membersCanCreateEvents ?? this.membersCanCreateEvents,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupPermissions &&
        other.membersCanInvite == membersCanInvite &&
        other.membersCanAddMembers == membersCanAddMembers &&
        other.membersCanCreateEvents == membersCanCreateEvents;
  }

  @override
  int get hashCode {
    return Object.hash(
      membersCanInvite,
      membersCanAddMembers,
      membersCanCreateEvents,
    );
  }

  @override
  String toString() {
    return 'GroupPermissions(membersCanInvite: $membersCanInvite, membersCanAddMembers: $membersCanAddMembers, membersCanCreateEvents: $membersCanCreateEvents)';
  }
}
