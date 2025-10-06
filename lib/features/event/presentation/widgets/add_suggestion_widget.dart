import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import 'add_suggestion_bottom_sheet.dart';
import 'votes_bottom_sheet.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';

/// Model for date/time suggestions
class DateTimeSuggestion {
  final String id;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;
  final List<String> voterIds;
  final bool isSelected;

  const DateTimeSuggestion({
    required this.id,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.voterIds,
    this.isSelected = false,
  });

  DateTimeSuggestion copyWith({
    String? id,
    DateTime? startDate,
    TimeOfDay? startTime,
    DateTime? endDate,
    TimeOfDay? endTime,
    List<String>? voterIds,
    bool? isSelected,
  }) {
    return DateTimeSuggestion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      voterIds: voterIds ?? this.voterIds,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Widget displaying date/time suggestions poll
class AddSuggestionWidget extends StatelessWidget {
  final List<DateTimeSuggestion> suggestions;
  final Function(String suggestionId) onVote;
  final VoidCallback onAddSuggestion;
  final VoidCallback? onPickFinal; // Only for host/admin
  final bool isHostOrAdmin;
  final DateTime eventStartDate;
  final TimeOfDay eventStartTime;
  final DateTime eventEndDate;
  final TimeOfDay eventEndTime;
  final List<RsvpVote> rsvpVotes; // To show on View Votes

  const AddSuggestionWidget({
    super.key,
    required this.suggestions,
    required this.onVote,
    required this.onAddSuggestion,
    this.onPickFinal,
    this.isHostOrAdmin = false,
    required this.eventStartDate,
    required this.eventStartTime,
    required this.eventEndDate,
    required this.eventEndTime,
    required this.rsvpVotes,
  });

  @override
  Widget build(BuildContext context) {
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
                onTap: () => showVotesBottomSheet(context, rsvpVotes),
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gaps.xs,
                    vertical: Gaps.xxs,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Votes',
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
          if (suggestions.isNotEmpty) ...[
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.sm),
                child: _SuggestionOption(
                  suggestion: suggestion,
                  onTap: () => onVote(suggestion.id),
                ),
              ),
            ),
            const SizedBox(height: Gaps.md),
          ],

          // Action buttons
          Row(
            children: [
              // Add Suggestion button (for everyone)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showAddSuggestionBottomSheet(
                    context,
                    eventStartDate: eventStartDate,
                    eventStartTime: eventStartTime,
                    eventEndDate: eventEndDate,
                    eventEndTime: eventEndTime,
                    onSuggestionAdded: onAddSuggestion,
                  ),
                  icon: const Icon(Icons.add, size: IconSizes.sm),
                  label: Text('Add Suggestion', style: AppText.bodyMediumEmph),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandColors.text1,
                    side: const BorderSide(color: BrandColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Pads.ctlH,
                      vertical: Pads.ctlV,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
              ),

              // Pick a final button (only for host/admin)
              if (isHostOrAdmin && onPickFinal != null) ...[
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: onPickFinal,
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.planning,
                      foregroundColor: BrandColors.bg1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Pads.ctlH,
                        vertical: Pads.ctlV,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                    ),
                    child: Text('Pick a final', style: AppText.bodyMediumEmph),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual suggestion option
class _SuggestionOption extends StatelessWidget {
  final DateTimeSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionOption({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Pads.ctlH),
        decoration: BoxDecoration(
          color: suggestion.isSelected
              ? BrandColors.planning.withOpacity(0.1)
              : BrandColors.bg3,
          border: Border.all(
            color: suggestion.isSelected
                ? BrandColors.planning
                : BrandColors.border,
            width: suggestion.isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Row(
          children: [
            // Date/Time info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateRange(),
                    style: AppText.bodyMediumEmph.copyWith(
                      color: suggestion.isSelected
                          ? BrandColors.planning
                          : BrandColors.text1,
                    ),
                  ),
                  const SizedBox(height: Gaps.xxs),
                  Text(
                    _formatTimeRange(),
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),

            // Vote count
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Gaps.sm,
                vertical: Gaps.xxs,
              ),
              decoration: BoxDecoration(
                color: suggestion.isSelected
                    ? BrandColors.planning
                    : BrandColors.border,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '${suggestion.voterIds.length}',
                style: AppText.bodyMedium.copyWith(
                  color: suggestion.isSelected
                      ? BrandColors.bg1
                      : BrandColors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
    final start = suggestion.startDate;
    final end = suggestion.endDate;

    if (start.day == end.day &&
        start.month == end.month &&
        start.year == end.year) {
      return '${start.day}/${start.month}/${start.year}';
    } else {
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
    }
  }

  String _formatTimeRange() {
    final startTime = suggestion.startTime;
    final endTime = suggestion.endTime;

    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }
}
