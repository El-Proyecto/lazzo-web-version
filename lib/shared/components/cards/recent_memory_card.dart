import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../../../features/home/domain/entities/recent_memory_entity.dart';

/// State for recent memory card
enum RecentMemoryCardState { normal, living, recap }

/// Card for displaying a recent memory with cover photo and event details
class RecentMemoryCard extends StatelessWidget {
  final RecentMemoryEntity memory;
  final VoidCallback? onTap;
  final RecentMemoryCardState state;

  const RecentMemoryCard({
    super.key,
    required this.memory,
    this.onTap,
    this.state = RecentMemoryCardState.normal,
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

              // Top right chip for living/recap states
              if (state != RecentMemoryCardState.normal)
                Positioned(
                  top: Pads.sectionV,
                  right: Pads.sectionH,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Pads.sectionV,
                      vertical: Pads.ctlVXss,
                    ),
                    decoration: BoxDecoration(
                      color: state == RecentMemoryCardState.living
                          ? BrandColors.living
                          : BrandColors.recap,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      state == RecentMemoryCardState.living ? 'Live' : 'Recap',
                      style: AppText.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
