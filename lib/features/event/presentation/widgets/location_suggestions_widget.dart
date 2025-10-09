import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/suggestion.dart';

/// Widget that displays location suggestions as votable polls
/// Only appears when suggestions are added from RSVP bottom sheet
class LocationSuggestionsWidget extends StatefulWidget {
  final List<LocationSuggestion> suggestions;
  final List<SuggestionVote> allVotes; // All votes for all suggestions
  final Function(String suggestionId) onVote;
  final Set<String> userVotes; // IDs of suggestions the user has voted for
  final bool isHost; // Whether current user is host/admin
  final VoidCallback onAddSuggestion; // Callback for add suggestion button

  const LocationSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.allVotes,
    required this.onVote,
    required this.userVotes,
    required this.isHost,
    required this.onAddSuggestion,
  });

  @override
  State<LocationSuggestionsWidget> createState() =>
      _LocationSuggestionsWidgetState();
}

class _LocationSuggestionsWidgetState extends State<LocationSuggestionsWidget> {
  // Helper method to get vote count for a specific suggestion
  int _getVoteCount(String suggestionId) {
    return widget.allVotes
        .where((vote) => vote.suggestionId == suggestionId)
        .length;
  }

  // Helper method to get votes for a specific suggestion
  List<SuggestionVote> _getVotesForSuggestion(String suggestionId) {
    return widget.allVotes
        .where((vote) => vote.suggestionId == suggestionId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(
        left: Insets.screenH,
        right: Insets.screenH,
        bottom: Gaps.lg,
      ),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(Pads.sectionH),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: BrandColors.text2,
                  size: IconSizes.md,
                ),
                const SizedBox(width: Gaps.sm),
                Text(
                  'Location Suggestions',
                  style: AppText.labelLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.isHost)
                  InkWell(
                    onTap: widget.onAddSuggestion,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gaps.sm,
                        vertical: Gaps.xs,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.bg3,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            size: IconSizes.sm,
                            color: BrandColors.text1,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: AppText.labelLarge.copyWith(
                              color: BrandColors.text1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Suggestions list
          ...widget.suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return _buildSuggestionCard(suggestion, index);
          }),

          const SizedBox(height: Gaps.sm),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(LocationSuggestion suggestion, int index) {
    final hasVoted = widget.userVotes.contains(suggestion.id);
    final isCurrentEvent = suggestion.id.contains('current_event');

    return Container(
      margin: EdgeInsets.only(
        left: Pads.sectionH,
        right: Pads.sectionH,
        bottom: index == widget.suggestions.length - 1 ? 0 : Gaps.sm,
      ),
      decoration: BoxDecoration(
        color: isCurrentEvent ? BrandColors.bg3 : BrandColors.bg1,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: hasVoted
            ? Border.all(color: BrandColors.planning, width: 1.5)
            : Border.all(color: BrandColors.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onVote(suggestion.id),
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Padding(
            padding: const EdgeInsets.all(Pads.sectionH),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCurrentEvent) ...[
                            const Icon(
                              Icons.star,
                              size: IconSizes.sm,
                              color: BrandColors.planning,
                            ),
                            const SizedBox(width: Gaps.xs),
                          ],
                          Expanded(
                            child: Text(
                              suggestion.locationName,
                              style: AppText.labelLarge.copyWith(
                                color: BrandColors.text1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (suggestion.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          suggestion.address!,
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Gaps.md),
                _buildVoteSection(suggestion, hasVoted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoteSection(LocationSuggestion suggestion, bool hasVoted) {
    return Column(
      children: [
        // Vote count with icon
        GestureDetector(
          onTap: () => _showVoteDetails(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gaps.sm,
              vertical: Gaps.xs,
            ),
            decoration: BoxDecoration(
              color: hasVoted ? BrandColors.planning : BrandColors.bg2,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: hasVoted
                  ? null
                  : Border.all(color: BrandColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasVoted ? Icons.check : Icons.location_on,
                  size: IconSizes.sm,
                  color: hasVoted ? Colors.white : BrandColors.text2,
                ),
                const SizedBox(width: 4),
                Text(
                  _getVoteCount(suggestion.id).toString(),
                  style: AppText.labelLarge.copyWith(
                    color: hasVoted ? Colors.white : BrandColors.text1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showVoteDetails(LocationSuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrandColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(Pads.sectionH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who voted for this location?',
              style: AppText.labelLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Gaps.lg),
            if (_getVotesForSuggestion(suggestion.id).isEmpty)
              Padding(
                padding: const EdgeInsets.all(Pads.sectionH),
                child: Text(
                  'No votes yet',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              )
            else
              ..._getVotesForSuggestion(suggestion.id).map((vote) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: BrandColors.bg3,
                    backgroundImage: vote.userAvatar != null
                        ? NetworkImage(vote.userAvatar!)
                        : null,
                    child: vote.userAvatar == null
                        ? Text(
                            vote.userName[0].toUpperCase(),
                            style: AppText.labelLarge.copyWith(
                              color: BrandColors.text1,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    vote.userName,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  subtitle: Text(
                    'Voted ${_formatTime(vote.createdAt)}',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
