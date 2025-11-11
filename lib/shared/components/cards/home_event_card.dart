import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Home event card state
/// Planning phase: pending (border color) or confirmed (green)
/// Living phase: living (purple)
/// Recap phase: recap (purple)
enum HomeEventCardState { pending, confirmed, living, recap }

/// Large event card for Home page "Next Event" section
/// Shows event details with state-specific border/chip colors
/// Includes Chat and Add Expense action buttons at bottom
class HomeEventCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String dateTime;
  final String location;
  final HomeEventCardState state;
  final int goingCount;
  final List<String> attendeeAvatars;
  final List<String> attendeeNames;
  final VoidCallback? onTap;
  final VoidCallback? onChatPressed;
  final VoidCallback? onAddExpensePressed;

  const HomeEventCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.state,
    required this.goingCount,
    required this.attendeeAvatars,
    required this.attendeeNames,
    this.onTap,
    this.onChatPressed,
    this.onAddExpensePressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Status chip row
            _buildDateAndStatus(),
            const SizedBox(height: Gaps.sm),

            // Event emoji, title, and location
            _buildEventInfo(),
            const SizedBox(height: Gaps.sm),

            // Attendees info
            _buildAttendeeInfo(),
            const SizedBox(height: Gaps.md),

            // Action buttons: Chat and Add Expense
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (state) {
      case HomeEventCardState.pending:
        return BrandColors.border;
      case HomeEventCardState.confirmed:
        return BrandColors.planning;
      case HomeEventCardState.living:
        return BrandColors.living;
      case HomeEventCardState.recap:
        return BrandColors.recap;
    }
  }

  Color _getChipBackgroundColor() {
    switch (state) {
      case HomeEventCardState.pending:
        return BrandColors.bg3;
      case HomeEventCardState.confirmed:
        return BrandColors.planning;
      case HomeEventCardState.living:
        return BrandColors.living;
      case HomeEventCardState.recap:
        return BrandColors.recap;
    }
  }

  Color _getChipBorderColor() {
    if (state == HomeEventCardState.pending) {
      return BrandColors.border;
    }
    return Colors.transparent;
  }

  Color _getChipTextColor() {
    if (state == HomeEventCardState.pending) {
      return BrandColors.text1;
    }
    return Colors.white;
  }

  String _getStatusLabel() {
    switch (state) {
      case HomeEventCardState.pending:
        return 'Pending';
      case HomeEventCardState.confirmed:
        return 'Confirmed';
      case HomeEventCardState.living:
        return 'Living';
      case HomeEventCardState.recap:
        return 'Recap';
    }
  }

  Widget _buildDateAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date
        Text(
          dateTime,
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text2,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.sectionV,
            vertical: Pads.ctlVXss,
          ),
          decoration: BoxDecoration(
            color: _getChipBackgroundColor(),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: _getChipBorderColor(),
              width: 1,
            ),
          ),
          child: Text(
            _getStatusLabel(),
            style: AppText.labelLarge.copyWith(
              color: _getChipTextColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Row(
      children: [
        // Event emoji
        Text(
          emoji,
          style: const TextStyle(fontSize: 42),
        ),
        const SizedBox(width: Gaps.md),

        // Event name and location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                location,
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
    );
  }

  Widget _buildAttendeeInfo() {
    return Row(
      children: [
        // Profile pictures
        _buildAttendeeAvatars(),
        const SizedBox(width: Gaps.xs),

        // Going count text with names
        Expanded(
          child: Text(
            _buildAttendeeText(),
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _buildAttendeeText() {
    if (attendeeNames.isEmpty) {
      return '$goingCount going';
    }

    if (attendeeNames.length == 1) {
      return '$goingCount going • ${attendeeNames.first}';
    }

    if (attendeeNames.length == 2) {
      return '$goingCount going • ${attendeeNames[0]} and ${attendeeNames[1]}';
    }

    if (attendeeNames.length >= 3) {
      final othersCount = attendeeNames.length - 2;
      return '$goingCount going • ${attendeeNames[0]}, ${attendeeNames[1]} and $othersCount other${othersCount > 1 ? 's' : ''}';
    }

    return '$goingCount going';
  }

  Widget _buildAttendeeAvatars() {
    const avatarSize = 24.0;
    const overlap = 8.0;

    if (attendeeAvatars.isEmpty) {
      return const SizedBox.shrink();
    }

    // Always show max 2 avatars + overflow indicator if there are more than 2
    final hasOverflow = attendeeAvatars.length > 2;
    final visibleAvatars = hasOverflow
        ? attendeeAvatars.take(2).toList()
        : attendeeAvatars.take(3).toList();
    final remainingCount = hasOverflow ? attendeeAvatars.length - 2 : 0;

    final totalWidth = hasOverflow
        ? avatarSize +
            2 * (avatarSize - overlap) // 2 avatars + overflow indicator
        : avatarSize + (visibleAvatars.length - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: [
          // Regular avatars
          ...visibleAvatars.asMap().entries.map((entry) {
            final index = entry.key;
            final avatarUrl = entry.value;

            return Positioned(
              left: index * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BrandColors.bg2,
                    width: 2,
                  ),
                  image: avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Handle image loading error
                          },
                        )
                      : null,
                ),
                child: avatarUrl.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: BrandColors.bg3,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 12,
                          color: BrandColors.text2,
                        ),
                      )
                    : null,
              ),
            );
          }),

          // Overflow indicator
          if (hasOverflow)
            Positioned(
              left: 2 * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.bg3,
                  border: Border.all(
                    color: BrandColors.bg2,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Chat button
        Expanded(
          child: GestureDetector(
            onTap: onChatPressed,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: BrandColors.text1,
                      size: 18,
                    ),
                    const SizedBox(width: Gaps.xs),
                    Text(
                      'Chat',
                      style: AppText.bodyMediumEmph.copyWith(
                        color: BrandColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Gaps.sm),

        // Add Expense button
        Expanded(
          child: GestureDetector(
            onTap: onAddExpensePressed,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: BrandColors.text1,
                      size: 18,
                    ),
                    const SizedBox(width: Gaps.xs),
                    Text(
                      'Add Expense',
                      style: AppText.bodyMediumEmph.copyWith(
                        color: BrandColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
