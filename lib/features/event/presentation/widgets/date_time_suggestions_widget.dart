import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/dialogs/common_bottom_sheet.dart';

/// Data model for date/time suggestion
class DateTimeSuggestion {
  final String id;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final int voteCount;
  final bool hasUserVoted;
  final List<SuggestionVote> votes; // List of votes for this suggestion

  const DateTimeSuggestion({
    required this.id,
    required this.startDateTime,
    this.endDateTime,
    required this.voteCount,
    required this.hasUserVoted,
    this.votes = const [],
  });
}

/// Individual vote for a suggestion
class SuggestionVote {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime? votedAt;

  const SuggestionVote({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.votedAt,
  });
}

/// Widget that displays date/time suggestions as votable polls
/// Only appears when suggestions are added from RSVP bottom sheet
class DateTimeSuggestionsWidget extends StatefulWidget {
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
  State<DateTimeSuggestionsWidget> createState() =>
      _DateTimeSuggestionsWidgetState();
}

class _DateTimeSuggestionsWidgetState extends State<DateTimeSuggestionsWidget> {
  late Set<String> _currentUserVotes;
  Set<String> _pendingVotes = {}; // Track votes being processed

  @override
  void initState() {
    super.initState();
    _currentUserVotes = Set.from(widget.userVotes);
  }

  @override
  void didUpdateWidget(DateTimeSuggestionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userVotes != widget.userVotes) {
      _currentUserVotes = Set.from(widget.userVotes);
    }
  }

  void _handleVote(String suggestionId) {
    // Prevent double-clicks
    if (_pendingVotes.contains(suggestionId)) return;

    _pendingVotes.add(suggestionId);

    // Call the parent callback
    widget.onVote(suggestionId);

    // Remove from pending after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _pendingVotes.remove(suggestionId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
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
            children: [
              Expanded(
                child: Text(
                  'Date & Time Suggestions',
                  style: AppText.labelLarge,
                ),
              ),
              // Only show view votes if there are any votes
              if (widget.suggestions.any((s) => s.voteCount > 0)) ...[
                InkWell(
                  onTap: () => _showViewVotesBottomSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
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
            ],
          ),
          const SizedBox(height: Gaps.md),

          // Suggestions list
          ...widget.suggestions.asMap().entries.map((entry) {
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
                  onPressed: widget.onAddSuggestion,
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
              if (widget.isHost) ...[
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _currentUserVotes.isNotEmpty
                        ? () => widget.onPickAsFinal(_currentUserVotes.first)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _currentUserVotes.isNotEmpty
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
    final hasUserVoted = _currentUserVotes.contains(suggestion.id);

    return AnimatedScale(
      scale: hasUserVoted ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: () => _handleVote(suggestion.id),
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
                      child: Text(
                        _formatDateRange(
                          suggestion.startDateTime,
                          suggestion.endDateTime,
                        ),
                      ),
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

  String _formatDateRange(DateTime startTime, DateTime? endTime) {
    if (endTime == null) {
      return _formatDate(startTime);
    }

    // Check if same day
    final startDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);

    if (startDate == endDate) {
      return _formatDate(startTime);
    } else {
      // Different days - show both dates
      return '${_formatDate(startTime)} - ${_formatDate(endTime)}';
    }
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
    // Organize votes by suggestion
    final Map<String, List<SuggestionVote>> votesBySuggestion = {};
    for (final suggestion in widget.suggestions) {
      votesBySuggestion[suggestion.id] = suggestion.votes;
    }

    CommonBottomSheet.show(
      context: context,
      title: 'Suggestion Votes',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create sections for each suggestion
          ...widget.suggestions.map((suggestion) {
            if (suggestion.votes.isEmpty) return const SizedBox.shrink();

            return Column(
              children: [
                _SuggestionVoteSection(
                  title: _formatDateRange(
                    suggestion.startDateTime,
                    suggestion.endDateTime,
                  ),
                  subtitle: _formatTimeRange(
                    suggestion.startDateTime,
                    suggestion.endDateTime,
                  ),
                  count: suggestion.votes.length,
                  votes: suggestion.votes,
                ),
                if (suggestion != widget.suggestions.last)
                  const SizedBox(height: Gaps.lg),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Vote section for a specific suggestion (similar to RSVP widget format)
class _SuggestionVoteSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;
  final List<SuggestionVote> votes;

  const _SuggestionVoteSection({
    required this.title,
    this.subtitle,
    required this.count,
    required this.votes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: título à esquerda, contador à direita
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppText.labelLarge.copyWith(color: BrandColors.planning),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count ${count == 1 ? "Vote" : "Votes"}',
              style: AppText.bodyMediumEmph.copyWith(color: BrandColors.text1),
            ),
          ],
        ),

        if (subtitle != null) ...[
          const SizedBox(height: Gaps.xxs),
          Text(
            subtitle!,
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: Gaps.md),

        // Vote list
        ...votes.map((vote) => _SuggestionVoteItem(vote: vote)),
      ],
    );
  }
}

/// Individual vote item for suggestions
class _SuggestionVoteItem extends StatelessWidget {
  final SuggestionVote vote;

  const _SuggestionVoteItem({required this.vote});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.sm),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: BrandColors.bg3,
            child: vote.userAvatar != null
                ? ClipOval(
                    child: Image.network(
                      vote.userAvatar!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: Gaps.sm),

          // Name
          Expanded(child: Text(vote.userName, style: AppText.bodyMedium)),

          // Date (if voted)
          if (vote.votedAt != null)
            Text(
              _formatVoteDate(vote.votedAt!),
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(Icons.person, color: BrandColors.text2, size: 20);
  }

  String _formatVoteDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
