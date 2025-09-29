import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/inputs/toggle_switch.dart';

/// Widget for configuring group member permissions
class GroupPermissionsSection extends StatelessWidget {
  final bool canEditSettings;
  final bool canAddMembers;
  final bool canSendMessages;
  final ValueChanged<bool> onEditSettingsChanged;
  final ValueChanged<bool> onAddMembersChanged;
  final ValueChanged<bool> onSendMessagesChanged;

  const GroupPermissionsSection({
    super.key,
    required this.canEditSettings,
    required this.canAddMembers,
    required this.canSendMessages,
    required this.onEditSettingsChanged,
    required this.onAddMembersChanged,
    required this.onSendMessagesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members permissions',
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
        const SizedBox(height: Gaps.xs),
        _PermissionRow(
          title: 'Edit Group Settings',
          value: canEditSettings,
          onChanged: onEditSettingsChanged,
        ),
        const SizedBox(height: Gaps.sm),
        _PermissionRow(
          title: 'Add Members',
          value: canAddMembers,
          onChanged: onAddMembersChanged,
        ),
        const SizedBox(height: Gaps.sm),
        _PermissionRow(
          title: 'Send Messages',
          value: canSendMessages,
          onChanged: onSendMessagesChanged,
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
        ),
        ToggleSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
