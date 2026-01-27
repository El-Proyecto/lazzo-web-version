import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/cards/memory_card.dart';
import '../../domain/entities/profile_entity.dart';

/// Tokenized memories section for displaying user memories in a grid
/// Shows section title and grid of memory cards
class MemoriesSection extends StatelessWidget {
  final List<MemoryEntity> memories;
  final String title;
  final Function(MemoryEntity)? onMemoryTap;

  const MemoriesSection({
    super.key,
    required this.memories,
    this.title = 'Memories',
    this.onMemoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),

        const SizedBox(height: Gaps.sm),

        // Memories Grid
        if (memories.isEmpty)
          Container(
            constraints: BoxConstraints(
              minHeight: 120,
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: BrandColors.text2,
                ),
                const SizedBox(height: Gaps.xs),
                Text(
                  'No memories yet',
                  style: AppText.bodyLarge.copyWith(color: BrandColors.text2),
                ),
              ],
            ),
          )
        else
          _buildMemoriesGrid(),
      ],
    );
  }

  Widget _buildMemoriesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card width based on available space
        // Total width minus spacing between cards (8px)
        final cardWidth = (constraints.maxWidth - Gaps.xs) / 2;

        return Column(
          children: [
            for (int i = 0; i < memories.length; i += 2)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i + 2 < memories.length ? Gaps.xs : 0,
                ),
                child: Row(
                  children: [
                    // First memory in row
                    Expanded(
                      child: SizedBox(
                        width: cardWidth,
                        child: MemoryCard(
                          title: memories[i].title,
                          coverImageUrl: memories[i].coverImageUrl,
                          date: memories[i].date,
                          location: memories[i].location,
                          borderColor: memories[i].activeBorderColor,
                          onTap: () => onMemoryTap?.call(memories[i]),
                        ),
                      ),
                    ),

                    // Spacing between cards
                    const SizedBox(width: Gaps.xs),

                    // Second memory in row (if exists)
                    if (i + 1 < memories.length)
                      Expanded(
                        child: SizedBox(
                          width: cardWidth,
                          child: MemoryCard(
                            title: memories[i + 1].title,
                            coverImageUrl: memories[i + 1].coverImageUrl,
                            date: memories[i + 1].date,
                            location: memories[i + 1].location,
                            borderColor: memories[i + 1].activeBorderColor,
                            onTap: () => onMemoryTap?.call(memories[i + 1]),
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: SizedBox(),
                      ), // Placeholder for alignment
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
