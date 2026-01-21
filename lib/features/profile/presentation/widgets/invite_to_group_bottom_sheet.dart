import 'package:flutter/material.dart';
import '../../../../shared/components/common/common_bottom_sheet.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/invite_group_entity.dart';

/// Bottom sheet for inviting user to groups
/// Shows list of groups with radio button selection (single-select)
class InviteToGroupBottomSheet extends StatefulWidget {
  final String userName;
  final List<InviteGroupEntity> groups;
  final Function(String groupId) onGroupSelected;

  const InviteToGroupBottomSheet({
    super.key,
    required this.userName,
    required this.groups,
    required this.onGroupSelected,
  });

  /// Show the invite to group bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String userName,
    required List<InviteGroupEntity> groups,
    required Function(String groupId) onGroupSelected,
  }) {
    return CommonBottomSheet.show(
      context: context,
      title: 'Invite to Group',
      content: InviteToGroupBottomSheet(
        userName: userName,
        groups: groups,
        onGroupSelected: onGroupSelected,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  State<InviteToGroupBottomSheet> createState() =>
      _InviteToGroupBottomSheetState();
}

class _InviteToGroupBottomSheetState extends State<InviteToGroupBottomSheet> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Pads.sectionH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 48,
              color: BrandColors.text2,
            ),
            const SizedBox(height: Gaps.md),
            Text(
              'No groups available',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.xs),
            Text(
              '${widget.userName} is already in all your groups',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Group list with checkboxes (no separators)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.groups.length,
          itemBuilder: (context, index) {
            final group = widget.groups[index];
            return _buildGroupItem(group);
          },
        ),

        const SizedBox(height: Gaps.md),

        // Send Invitation button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedGroupId != null
                  ? () {
                      Navigator.of(context).pop();
                      widget.onGroupSelected(_selectedGroupId!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedGroupId != null
                    ? BrandColors.planning
                    : BrandColors.bg3,
                foregroundColor: Colors.white,
                disabledBackgroundColor: BrandColors.bg3,
                disabledForegroundColor: BrandColors.text2,
                padding: const EdgeInsets.symmetric(vertical: Gaps.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
              child: Text(
                'Send Invitation',
                style: AppText.labelLarge.copyWith(
                  color: _selectedGroupId != null
                      ? Colors.white
                      : BrandColors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: Gaps.md),
      ],
    );
  }

  Widget _buildGroupItem(InviteGroupEntity group) {
    final isSelected = _selectedGroupId == group.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGroupId = group.id;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.sectionH,
          vertical: Gaps.sm,
        ),
        child: Row(
          children: [
            // Group photo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.sm),
                color: BrandColors.bg3,
                image: group.groupPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(group.groupPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: group.groupPhotoUrl == null
                  ? const Icon(
                      Icons.group,
                      size: 24,
                      color: BrandColors.text2,
                    )
                  : null,
            ),

            const SizedBox(width: Gaps.md),

            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} members',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: Gaps.md),

            // Radio button (aligned to the right)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? BrandColors.planning : BrandColors.border,
                  width: 2,
                ),
                color: isSelected ? BrandColors.planning : Colors.transparent,
              ),
              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
