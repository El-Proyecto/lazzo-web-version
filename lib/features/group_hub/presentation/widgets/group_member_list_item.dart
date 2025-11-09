import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/group_member_entity.dart';

/// Widget for displaying a group member in the members list
class GroupMemberListItem extends StatelessWidget {
  final GroupMemberEntity member;
  final bool isCurrentUserAdmin;
  final VoidCallback onTap;
  final VoidCallback? onPromoteToAdmin;
  final VoidCallback? onDemoteFromAdmin;
  final VoidCallback? onRemoveFromGroup;

  const GroupMemberListItem({
    super.key,
    required this.member,
    required this.isCurrentUserAdmin,
    required this.onTap,
    this.onPromoteToAdmin,
    this.onDemoteFromAdmin,
    this.onRemoveFromGroup,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.sectionH,
          vertical: Gaps.md,
        ),
        child: Row(
          children: [
            // Profile image
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.bg3,
                image: member.profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(member.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: member.profileImageUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 20,
                      color: BrandColors.text2,
                    )
                  : null,
            ),

            const SizedBox(width: Gaps.md),

            // Name
            Expanded(
              child: Text(
                member.name,
                style: AppText.bodyMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
            ),

            // Admin badge
            if (member.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gaps.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: BrandColors.bg3,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  'Admin',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontSize: 12,
                  ),
                ),
              ),

            // Three-dot menu (only for admins, not on current user)
            if (isCurrentUserAdmin && !member.isCurrentUser) ...[
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: BrandColors.text2,
                  size: 20,
                ),
                color: BrandColors.bg3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                onSelected: (value) {
                  if (value == 'promote' && onPromoteToAdmin != null) {
                    onPromoteToAdmin!();
                  } else if (value == 'demote' && onDemoteFromAdmin != null) {
                    onDemoteFromAdmin!();
                  } else if (value == 'remove' && onRemoveFromGroup != null) {
                    onRemoveFromGroup!();
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];

                  // Promote/Demote option
                  if (member.isAdmin) {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'demote',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_downward,
                              color: BrandColors.text1,
                              size: 18,
                            ),
                            const SizedBox(width: Gaps.sm),
                            Text(
                              'Demote from Admin',
                              style: AppText.bodyMedium.copyWith(
                                color: BrandColors.text1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'promote',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward,
                              color: BrandColors.text1,
                              size: 18,
                            ),
                            const SizedBox(width: Gaps.sm),
                            Text(
                              'Promote to Admin',
                              style: AppText.bodyMedium.copyWith(
                                color: BrandColors.text1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Remove option
                  items.add(
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_remove,
                            color: BrandColors.cantVote,
                            size: 18,
                          ),
                          const SizedBox(width: Gaps.sm),
                          Text(
                            'Remove from Group',
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.cantVote,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  return items;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
