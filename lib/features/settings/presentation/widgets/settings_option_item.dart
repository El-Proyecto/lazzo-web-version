import 'package:flutter/material.dart';
import '../../../../shared/components/inputs/toggle_switch.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

enum SettingsOptionTrailingType {
  toggle,
  selection,
  arrow,
  none,
}

class SettingsOptionTrailing {
  final SettingsOptionTrailingType type;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final String? selectionValue;
  final VoidCallback? onTap;

  const SettingsOptionTrailing._({
    required this.type,
    this.toggleValue,
    this.onToggleChanged,
    this.selectionValue,
    this.onTap,
  });

  factory SettingsOptionTrailing.toggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsOptionTrailing._(
      type: SettingsOptionTrailingType.toggle,
      toggleValue: value,
      onToggleChanged: onChanged,
    );
  }

  factory SettingsOptionTrailing.selection({
    required String value,
    required VoidCallback onTap,
  }) {
    return SettingsOptionTrailing._(
      type: SettingsOptionTrailingType.selection,
      selectionValue: value,
      onTap: onTap,
    );
  }

  factory SettingsOptionTrailing.arrow({
    required VoidCallback onTap,
  }) {
    return SettingsOptionTrailing._(
      type: SettingsOptionTrailingType.arrow,
      onTap: onTap,
    );
  }

  factory SettingsOptionTrailing.none({
    required VoidCallback onTap,
  }) {
    return SettingsOptionTrailing._(
      type: SettingsOptionTrailingType.none,
      onTap: onTap,
    );
  }
}

class SettingsOptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final SettingsOptionTrailing trailing;
  final bool isDanger;

  const SettingsOptionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.trailing,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDanger ? BrandColors.cantVote : BrandColors.text1;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH,
        vertical: Pads.ctlV,
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            icon,
            color: textColor,
            size: 24,
          ),

          const SizedBox(width: Gaps.md),

          // Title
          Expanded(
            child: Text(
              title,
              style: AppText.bodyLarge.copyWith(
                color: textColor,
              ),
            ),
          ),

          const SizedBox(width: Gaps.md),

          // Trailing
          _buildTrailing(),
        ],
      ),
    );

    // Wrap with GestureDetector if has onTap
    if (trailing.onTap != null &&
        trailing.type != SettingsOptionTrailingType.toggle) {
      content = GestureDetector(
        onTap: trailing.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }

  Widget _buildTrailing() {
    switch (trailing.type) {
      case SettingsOptionTrailingType.toggle:
        return ToggleSwitch(
          value: trailing.toggleValue ?? false,
          onChanged: trailing.onToggleChanged!,
        );

      case SettingsOptionTrailingType.selection:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trailing.selectionValue ?? '',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
            ),
            const SizedBox(width: Gaps.xs),
            const Icon(
              Icons.arrow_forward_ios,
              color: BrandColors.text2,
              size: 16,
            ),
          ],
        );

      case SettingsOptionTrailingType.arrow:
        return const Icon(
          Icons.arrow_forward_ios,
          color: BrandColors.text2,
          size: 16,
        );

      case SettingsOptionTrailingType.none:
        return const SizedBox.shrink();
    }
  }
}
