import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Tokenized memory card for displaying individual memories
/// Shows cover image, title, location, and date with gradient overlay
class MemoryCard extends StatelessWidget {
  final String title;
  final String? coverImageUrl;
  final DateTime date;
  final String? location;
  final VoidCallback? onTap;
  final Color? borderColor; // Border color for active memories (living/recap)

  const MemoryCard({
    super.key,
    required this.title,
    this.coverImageUrl,
    required this.date,
    this.location,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0, // Square aspect ratio
        child: Container(
          decoration: borderColor != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: borderColor!,
                    width: 3,
                  ),
                )
              : null,
          child: Stack(
            children: [
              // Background Image
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: ShapeDecoration(
                  image: coverImageUrl != null &&
                          coverImageUrl!.isNotEmpty &&
                          coverImageUrl != 'placeholder'
                      ? DecorationImage(
                          image: NetworkImage(coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: coverImageUrl == null ||
                          coverImageUrl!.isEmpty ||
                          coverImageUrl == 'placeholder'
                      ? BrandColors.bg3
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                child: coverImageUrl == null ||
                        coverImageUrl!.isEmpty ||
                        coverImageUrl == 'placeholder'
                    ? const Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: BrandColors.text2,
                      )
                    : null,
              ),

              // Gradient Overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),

              // Content
              Positioned(
                left: Pads.ctlH,
                bottom: Pads.ctlV,
                right: Pads.ctlH,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: AppText.bodyMediumEmph.copyWith(
                        color: BrandColors.text1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Location and Date
                    Text(
                      _formatLocationAndDate(location, date),
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
      ),
    );
  }

  String _formatLocationAndDate(String? location, DateTime date) {
    final shortDate = _formatDateShort(date);

    // Always show both location and date
    if (location == null || location.isEmpty) {
      return 'Unknown • $shortDate';
    }

    // Smart location truncation - keep main words
    final truncatedLocation = _truncateLocation(location);
    return '$truncatedLocation • $shortDate';
  }

  String _truncateLocation(String location) {
    // Remove common suffixes and keep main words
    final cleanLocation = location
        .replaceAll(
          RegExp(
            r',\s*(Portugal|Brasil|Brazil|Italy|Spain|France)$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r',\s*Lisboa$', caseSensitive: false), '')
        .replaceAll(RegExp(r',\s*Lisbon$', caseSensitive: false), '');

    final words = cleanLocation.split(' ');

    // If location is short enough, return as is
    if (cleanLocation.length <= 15) {
      return cleanLocation;
    }

    // Keep first 1-2 main words
    if (words.length == 1) {
      return words[0].length > 12
          ? '${words[0].substring(0, 12)}...'
          : words[0];
    } else if (words.length >= 2) {
      final firstTwo = '${words[0]} ${words[1]}';
      return firstTwo.length > 15 ? words[0] : firstTwo;
    }

    return cleanLocation.length > 15
        ? '${cleanLocation.substring(0, 15)}...'
        : cleanLocation;
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
