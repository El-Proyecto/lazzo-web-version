import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Tokenized user info card showing profile picture, name, location and birthday
/// Used for displaying user profile information
class UserInfoCard extends StatelessWidget {
  final String name;
  final String? profileImageUrl;
  final String? location;
  final DateTime? birthday;

  const UserInfoCard({
    super.key,
    required this.name,
    this.profileImageUrl,
    this.location,
    this.birthday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Picture
        Container(
          width: 152,
          height: 152,
          decoration: ShapeDecoration(
            image: profileImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(profileImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: profileImageUrl == null ? BrandColors.bg3 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(76),
            ),
          ),
          child: profileImageUrl == null
              ? const Icon(Icons.person, size: 64, color: BrandColors.text2)
              : null,
        ),

        const SizedBox(height: Gaps.xs),

        // Name
        Text(
          name,
          style: AppText.headlineMedium.copyWith(color: BrandColors.text1),
        ),

        // Location (if provided)
        if (location != null) ...[
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
                location!,
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text2,
                ),
              ),
            ],
          ),
        ],

        // Birthday (if provided)
        if (birthday != null) ...[
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
                _formatBirthday(birthday!),
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
