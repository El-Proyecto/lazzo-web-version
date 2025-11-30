import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class SettingsProfileSection extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final VoidCallback onTap;

  const SettingsProfileSection({
    super.key,
    this.avatarUrl,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 32,
              backgroundColor: BrandColors.bg3,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: AppText.bodyLarge.copyWith(
                        color: BrandColors.text1,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: Gaps.md),

            // Name and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppText.bodyLarge.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to edit profile',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              color: BrandColors.text2,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
