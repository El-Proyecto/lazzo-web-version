import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Data model for date/time suggestion
class DateTimeSuggestion {
  final String id;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final int voteCount;
  final bool hasUserVoted;

  const DateTimeSuggestion({
    required this.id,
    required this.startDateTime,
    this.endDateTime,
    required this.voteCount,
    required this.hasUserVoted,
  });
}

/// Widget that displays date/time suggestions as votable polls
/// Only appears when suggestions are added from RSVP bottom sheet
class DateTimeSuggestionsWidget extends StatelessWidget {
  final List<DateTimeSuggestion> suggestions;
  final Function(String suggestionId) onVote;
  final Set<String> userVotes; // IDs of suggestions the user has voted for
  final bool isHost; // Whether current user is host/admin
  final VoidCallback onAddSuggestion; // Callback for add suggestion button
  final Function(String suggestionId)
  onPickAsFinal; // Callback for pick as final

  const DateTimeSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.onVote,
    required this.userVotes,
    required this.isHost,
    required this.onAddSuggestion,
    required this.onPickAsFinal,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Date & Time Suggestions', style: AppText.labelLarge),
              InkWell(
                onTap: () => _showViewVotesBottomSheet(context),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gaps.xs,
                    vertical: Gaps.xxs,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View votes',
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                      ),
                      const SizedBox(width: Gaps.xxs),
                      const Icon(
                        Icons.chevron_right,
                        size: IconSizes.sm,
                        color: BrandColors.text2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.md),

          // Suggestions list
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;

            return Column(
              children: [
                if (index > 0) const SizedBox(height: Gaps.sm),
                _buildSuggestionOption(suggestion),
              ],
            );
          }),

          // Action buttons
          const SizedBox(height: Gaps.lg),
          Row(
            children: [
              // Add Suggestion button
              Expanded(
                child: OutlinedButton(
                  onPressed: onAddSuggestion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandColors.text1,
                    side: const BorderSide(color: BrandColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Pads.ctlH,
                      vertical: Pads.ctlV,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Add Suggestion', style: AppText.bodyMediumEmph),
                ),
              ),

              // Pick as Final button (only for host)
              if (isHost) ...[
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: userVotes.isNotEmpty
                        ? () => onPickAsFinal(userVotes.first)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: userVotes.isNotEmpty
                          ? Colors.green
                          : BrandColors.text2,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Pads.ctlH,
                        vertical: Pads.ctlV,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Pick as Final', style: AppText.bodyMediumEmph),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionOption(DateTimeSuggestion suggestion) {
    final hasUserVoted = userVotes.contains(suggestion.id);

    return AnimatedScale(
      scale: hasUserVoted ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: () => onVote(suggestion.id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Pads.ctlH),
          decoration: BoxDecoration(
            color: hasUserVoted
                ? BrandColors.planning.withValues(alpha: 0.1)
                : BrandColors.bg3,
            borderRadius: BorderRadius.circular(10),
            border: hasUserVoted
                ? Border.all(color: BrandColors.planning, width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Vote indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasUserVoted
                      ? BrandColors.planning
                      : Colors.transparent,
                  border: Border.all(
                    color: hasUserVoted
                        ? BrandColors.planning
                        : BrandColors.text2,
                    width: 1.5,
                  ),
                ),
                child: hasUserVoted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: Gaps.sm),

              // Date and time info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppText.bodyMedium.copyWith(
                        color: hasUserVoted
                            ? BrandColors.text1
                            : BrandColors.text1,
                        fontWeight: hasUserVoted
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      child: Text(_formatDate(suggestion.startDateTime)),
                    ),
                    const SizedBox(height: Gaps.xxs),
                    // Time range
                    Text(
                      _formatTimeRange(
                        suggestion.startDateTime,
                        suggestion.endDateTime,
                      ),
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Vote count
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: Gaps.xs,
                  vertical: Gaps.xxs,
                ),
                decoration: BoxDecoration(
                  color: hasUserVoted
                      ? BrandColors.planning
                      : BrandColors.border,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  '${suggestion.voteCount}',
                  style: AppText.bodyMedium.copyWith(
                    color: hasUserVoted ? Colors.white : BrandColors.text2,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];

    return '$weekday, $month ${dateTime.day}';
  }

  String _formatTimeRange(DateTime startTime, DateTime? endTime) {
    String formatTime(DateTime time) {
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$displayHour:$minuteStr $period';
    }

    final startFormatted = formatTime(startTime);
    if (endTime == null) {
      return startFormatted;
    }

    final endFormatted = formatTime(endTime);
    return '$startFormatted - $endFormatted';
  }

  void _showViewVotesBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Radii.md),
              topRight: Radius.circular(Radii.md),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: Gaps.sm),
                decoration: BoxDecoration(
                  color: BrandColors.text2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(Pads.sectionH),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Suggestion Votes', style: AppText.titleMediumEmph),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: BrandColors.text2),
                    ),
                  ],
                ),
              ),

              // Content - organized by suggestions
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.sectionH,
                  ),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: Gaps.lg),
                      padding: const EdgeInsets.all(Pads.sectionH),
                      decoration: BoxDecoration(
                        color: BrandColors.bg3,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Suggestion details
                          Text(
                            _formatDate(suggestion.startDateTime),
                            style: AppText.bodyMediumEmph,
                          ),
                          const SizedBox(height: Gaps.xxs),
                          Text(
                            _formatTimeRange(
                              suggestion.startDateTime,
                              suggestion.endDateTime,
                            ),
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                            ),
                          ),
                          const SizedBox(height: Gaps.sm),

                          // Vote count
                          Text(
                            '${suggestion.voteCount} votes',
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.planning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // TODO: Add list of users who voted for this suggestion
                          const SizedBox(height: Gaps.xs),
                          Text(
                            'Users who voted: [To be implemented]',
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
