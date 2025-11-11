import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/profile_entity.dart';

/// Tokenized user info card showing profile picture, name, location and birthday
/// Used for displaying user profile information
class UserInfoCard extends StatelessWidget {
  final ProfileEntity profile;

  const UserInfoCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Picture (now using signed URL from repository)
        Container(
          width: 120,
          height: 120,
          decoration: ShapeDecoration(
            color: BrandColors.bg3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(90),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(90),
            child: profile.profileImageUrl != null &&
                    profile.profileImageUrl!.isNotEmpty
                ? Image.network(
                    profile.profileImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: BrandColors.planning,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        size: 48,
                        color: BrandColors.text2),
                  )
                : const Icon(Icons.person, size: 48, color: BrandColors.text2),
          ),
        ),

        const SizedBox(height: Gaps.sm),

        // Name
        Text(
          profile.name,
          style: AppText.subtitleMuted.copyWith(color: BrandColors.text1),
        ),

        // Location (if provided)
        if (profile.location != null) ...[
          const SizedBox(height: Gaps.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: BrandColors.text2,
              ),
              const SizedBox(width: Gaps.xs),
              Text(
                profile.location!,
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            ],
          ),
        ],

        // Birthday (if provided)
        if (profile.birthday != null) ...[
          const SizedBox(height: Gaps.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Opacity(
                opacity: 0.6,
                child: Icon(
                  Icons.cake_outlined,
                  size: 16,
                  color: BrandColors.text2,
                ),
              ),
              const SizedBox(width: Gaps.xs),
              Text(
                _formatBirthday(profile.birthday!),
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatBirthday(DateTime birthday) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${birthday.day} ${months[birthday.month - 1]}';
  }
}
