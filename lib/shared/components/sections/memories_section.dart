import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../cards/memory_card.dart';

/// Memory data interface for the generic memories section
abstract class MemoryData {
  String get title;
  String? get coverImageUrl;
  DateTime get date;
  String? get location;
}

/// Tokenized memories section for displaying memories in a grid
/// Shows section title and grid of memory cards
/// Generic implementation that works with any memory data type
class MemoriesSection<T extends MemoryData> extends StatelessWidget {
  final List<T> memories;
  final String title;
  final Function(T)? onMemoryTap;
  final bool enableScroll;

  const MemoriesSection({
    super.key,
    required this.memories,
    this.title = 'Memories',
    this.onMemoryTap,
    this.enableScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    if (enableScroll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable memories grid
          if (memories.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: Insets.screenH,
                  right: Insets.screenH,
                  bottom: Gaps.md,
                ),
                child: _buildMemoriesGrid(),
              ),
            ),
        ],
      );
    }

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
        if (memories.isEmpty) _buildEmptyState() else _buildMemoriesGrid(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
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
