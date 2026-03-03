import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// ShareCard component with frosted glass effect for sharing memories
/// Displays hero photo, thumbnails, and event details on a wallpaper background
/// Optimized for 1080x1920 (9:16) Instagram Story format
class ShareCard extends StatelessWidget {
  final String title;
  final String? location;
  final DateTime eventDate;
  final int peopleCount;
  final String heroPhotoUrl;
  final List<String> thumbnailUrls;

  const ShareCard({
    super.key,
    required this.title,
    this.location,
    required this.eventDate,
    required this.peopleCount,
    required this.heroPhotoUrl,
    required this.thumbnailUrls,
  });

  @override
  Widget build(BuildContext context) {
    // Container with 9:16 aspect ratio for Instagram Story
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wallpaper.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 32.0,
          vertical: 48.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(32.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                  left: Gaps.md, right: Gaps.md, top: Gaps.md, bottom: Gaps.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Photo section — single tall photo or hero + thumbnails
                  if (thumbnailUrls.isEmpty)
                    // Single photo: height = hero (square) + gap + thumbnail row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final thumbnailRowHeight = (width - 2 * Gaps.xs) / 3;
                        final totalHeight =
                            width + Gaps.xs + thumbnailRowHeight;
                        return SizedBox(
                          height: totalHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.md),
                            child: Image.network(
                              heroPhotoUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: BrandColors.bg3,
                                  child: const Icon(
                                    Icons.image,
                                    color: BrandColors.text2,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    )
                  else ...[
                    // Hero photo (square)
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.md),
                        child: Image.network(
                          heroPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: BrandColors.bg3,
                              child: const Icon(
                                Icons.image,
                                color: BrandColors.text2,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: Gaps.xs),

                    // Thumbnails row (square aspect ratio - always 3 equal items)
                    Row(
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: Gaps.xs),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Radii.sm),
                                child: i < thumbnailUrls.length
                                    ? Image.network(
                                        thumbnailUrls[i],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: BrandColors.bg3,
                                            child: const Icon(
                                              Icons.image,
                                              color: BrandColors.text2,
                                              size: 24,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: BrandColors.bg3,
                                        child: const Icon(
                                          Icons.image,
                                          color: BrandColors.text2,
                                          size: 24,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: Gaps.xs),

                  // Text details
                  Text(
                    title,
                    style: AppText.titleMediumEmph.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: Gaps.xxs),

                  Text(
                    _buildSecondaryLine(),
                    style: AppText.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: Gaps.sm),

                  // "made with LAZZO" caption
                  Center(
                    child: Text(
                      'made with LAZZO',
                      style: AppText.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildSecondaryLine() {
    final parts = <String>[];

    if (location != null && location!.isNotEmpty) {
      parts.add(location!);
    }

    parts.add(DateFormat('d MMM yyyy').format(eventDate));

    return parts.join(' • ');
  }
}
