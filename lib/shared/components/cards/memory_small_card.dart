import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Small memory card for calendar bottom sheet and list views
/// Shows cover photo on the left and event info (title, date, location) on the right
class MemorySmallCard extends StatelessWidget {
  final String title;
  final String dateTime;
  final String? location;
  final String? coverPhotoUrl;
  final VoidCallback? onTap;

  const MemorySmallCard({
    super.key,
    required this.title,
    required this.dateTime,
    this.location,
    this.coverPhotoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlVXs),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            // Cover photo on the left
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: SizedBox(
                width: 56,
                height: 56,
                child: coverPhotoUrl != null
                    ? Image.network(
                        coverPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            // Info on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Gaps.xxs),
                  Text(
                    location != null ? '$dateTime • $location' : dateTime,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: BrandColors.bg3,
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          color: BrandColors.text2,
          size: 24,
        ),
      ),
    );
  }
}
