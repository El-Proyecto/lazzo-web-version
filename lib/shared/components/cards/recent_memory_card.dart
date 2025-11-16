import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../../../features/home/domain/entities/recent_memory_entity.dart';

/// Card for displaying a recent memory with cover photo and event details
class RecentMemoryCard extends StatelessWidget {
  final RecentMemoryEntity memory;
  final VoidCallback? onTap;

  const RecentMemoryCard({
    super.key,
    required this.memory,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          height: 200,
          decoration: const BoxDecoration(
            color: BrandColors.bg2,
          ),
          child: Stack(
            children: [
              // Cover photo
              if (memory.coverPhotoUrl != null)
                Positioned.fill(
                  child: Image.network(
                    memory.coverPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.photo,
                          color: BrandColors.text2,
                          size: IconSizes.lg,
                        ),
                      );
                    },
                  ),
                ),

              // Bottom overlay with bg2 and event details
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: BrandColors.bg2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.sectionH,
                    vertical: Pads.sectionV,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event name
                      Text(
                        memory.eventName,
                        style: AppText.labelLarge.copyWith(
                          color: BrandColors.text1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Gaps.xs),
                      // Location and date
                      Text(
                        memory.locationDateText,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
