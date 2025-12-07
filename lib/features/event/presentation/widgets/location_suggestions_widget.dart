import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/common_bottom_sheet.dart';
import '../../../../shared/components/common/top_banner.dart';
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
  final Function(LocationSuggestion selectedSuggestion)
      onPickLocation; // Callback for pick location
  final String? currentEventLocationName; // Current event location name
  final String? currentEventAddress; // Current event address
  final int
      currentEventGoingCount; // Number of 'Can' votes from RSVP for current event

  const LocationSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.allVotes,
    required this.onVote,
    required this.userVotes,
    required this.isHost,
    required this.onAddSuggestion,
    required this.onPickLocation,
    this.currentEventLocationName,
    this.currentEventAddress,
    this.currentEventGoingCount = 0,
  });

  @override
  State<LocationSuggestionsWidget> createState() =>
      _LocationSuggestionsWidgetState();
}

class _LocationSuggestionsWidgetState extends State<LocationSuggestionsWidget> {
  late Set<String> _currentUserVotes;
  final Set<String> _pendingVotes = {}; // Track votes being processed
  bool _isSelectionMode = false; // Whether in location selection mode
  String? _selectedSuggestionId; // ID of selected suggestion for pick location

  @override
  void initState() {
    super.initState();
    _currentUserVotes = Set.from(widget.userVotes);
  }

  @override
  void didUpdateWidget(LocationSuggestionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userVotes != widget.userVotes) {
      _currentUserVotes = Set.from(widget.userVotes);
    }
  }

  void _handleVote(String suggestionId) {
    // If in selection mode, handle selection instead of voting
    if (_isSelectionMode) {
      setState(() {
        _selectedSuggestionId =
            _selectedSuggestionId == suggestionId ? null : suggestionId;
      });
      return;
    }

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

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedSuggestionId = null;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSuggestionId = null;
    });
  }

  void _confirmLocationSelection() {
    if (_selectedSuggestionId != null) {
      final selectedSuggestion = widget.suggestions.firstWhere(
        (s) => s.id == _selectedSuggestionId,
      );
      widget.onPickLocation(selectedSuggestion);
    }
  }

  /// Check if a suggestion matches the current event location
  bool _isCurrentEventSuggestion(LocationSuggestion suggestion) {
    if (widget.currentEventLocationName == null) return false;

    // Compare location name
    if (suggestion.locationName != widget.currentEventLocationName) {
      return false;
    }

    // Compare address (both must be null or both must match)
    if (suggestion.address != widget.currentEventAddress) {
      return false;
    }

    return true;
  }

  // Helper method to get vote count for a specific suggestion
  int _getVoteCount(String suggestionId) {
    // Find the suggestion to check if it's the current event
    final suggestion = widget.suggestions.firstWhere(
      (s) => s.id == suggestionId,
      orElse: () => widget.suggestions.first,
    );

    // If this is the current event location, return going count from RSVP
    if (_isCurrentEventSuggestion(suggestion)) {
      return widget.currentEventGoingCount;
    }

    // Otherwise return vote count from suggestion votes
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
                child: Text('Location Suggestions', style: AppText.labelLarge),
              ),
              // Fixed width container to prevent expansion when View votes appears
              SizedBox(
                width: 100,
                child: widget.suggestions.any((s) => _getVoteCount(s.id) > 0)
                    ? InkWell(
                        onTap: () => _showViewVotesBottomSheet(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                      )
                    : const SizedBox.shrink(),
              ),
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
          const SizedBox(height: Gaps.md),
          Row(
            children: [
              if (_isSelectionMode) ...[
                // Cancel button in selection mode
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exitSelectionMode,
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
                    child: Text('Cancel', style: AppText.bodyMediumEmph),
                  ),
                ),
                const SizedBox(width: Gaps.sm),
                // Confirm button in selection mode
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedSuggestionId != null
                        ? _confirmLocationSelection
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedSuggestionId != null
                          ? BrandColors.planning
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
                    child: Text('Confirm', style: AppText.bodyMediumEmph),
                  ),
                ),
              ] else ...[
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
                    child: Text(
                      'Add Suggestion',
                      style: AppText.bodyMediumEmph,
                    ),
                  ),
                ),

                // Pick Location button (only for host)
                if (widget.isHost) ...[
                  const SizedBox(width: Gaps.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _enterSelectionMode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrandColors.text1,
                        side: const BorderSide(color: BrandColors.border),
                        backgroundColor: BrandColors.bg3,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Pads.ctlH,
                          vertical: Pads.ctlV,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Set Location',
                        style: AppText.bodyMediumEmph,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionOption(LocationSuggestion suggestion) {
    final hasUserVoted = _currentUserVotes.contains(suggestion.id);
    final isCurrentEvent = _isCurrentEventSuggestion(suggestion);
    final isSelected =
        _isSelectionMode && _selectedSuggestionId == suggestion.id;
    final shouldShowBorder =
        _isSelectionMode ? isSelected : !isCurrentEvent && hasUserVoted;

    return AnimatedScale(
      scale: hasUserVoted ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: isCurrentEvent
            ? () {
                TopBanner.showInfo(
                  context,
                  message:
                      'This is the current event location. You cannot vote on it.',
                );
              }
            : () => _handleVote(suggestion.id),
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Pads.ctlH),
              decoration: BoxDecoration(
                color: _isSelectionMode
                    ? (isSelected
                        ? BrandColors.planning.withValues(alpha: 0.1)
                        : BrandColors.bg3)
                    : isCurrentEvent
                        ? BrandColors.bg3
                        : hasUserVoted
                            ? BrandColors.planning.withValues(alpha: 0.1)
                            : BrandColors.bg3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Vote indicator, star for current event, or selection indicator
                  if (isCurrentEvent) ...[
                    const Icon(Icons.star, size: 20, color: BrandColors.text2),
                  ] else if (_isSelectionMode) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? BrandColors.planning
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? BrandColors.planning
                              : BrandColors.text2,
                          width: isSelected ? 2.2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isSelected ? 8 : 0,
                          height: isSelected ? 8 : 0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
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
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                  const SizedBox(width: Gaps.sm),

                  // Location info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location name
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: AppText.bodyMedium.copyWith(
                            color: _isSelectionMode
                                ? (isSelected
                                    ? BrandColors.text1
                                    : BrandColors.text1)
                                : isCurrentEvent
                                    ? BrandColors.text2
                                    : hasUserVoted
                                        ? BrandColors.text1
                                        : BrandColors.text1,
                            fontWeight: _isSelectionMode
                                ? (isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)
                                : isCurrentEvent
                                    ? FontWeight.normal
                                    : hasUserVoted
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                          ),
                          child: Text(suggestion.locationName),
                        ),
                        const SizedBox(height: Gaps.xxs),
                        // Address
                        Text(
                          suggestion.address ?? 'address not defined',
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vote count - perfect circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSelectionMode
                          ? (isSelected
                              ? BrandColors.planning
                              : BrandColors.border)
                          : isCurrentEvent
                              ? BrandColors.border
                              : hasUserVoted
                                  ? BrandColors.planning
                                  : BrandColors.border,
                    ),
                    child: Center(
                      child: Text(
                        '${_getVoteCount(suggestion.id)}',
                        style: AppText.bodyMedium.copyWith(
                          color: _isSelectionMode
                              ? (isSelected ? Colors.white : BrandColors.text2)
                              : isCurrentEvent
                                  ? BrandColors.text2
                                  : hasUserVoted
                                      ? Colors.white
                                      : BrandColors.text2,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Internal border overlay to prevent size expansion
            if (shouldShowBorder)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BrandColors.planning,
                      width: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showViewVotesBottomSheet(BuildContext context) {
    // Organize votes by suggestion
    final Map<String, List<SuggestionVote>> votesBySuggestion = {};
    for (final suggestion in widget.suggestions) {
      votesBySuggestion[suggestion.id] = _getVotesForSuggestion(suggestion.id);
    }

    CommonBottomSheet.show(
      context: context,
      title: 'Suggestion Votes',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create sections for each suggestion
          ...widget.suggestions.map((suggestion) {
            final votes = _getVotesForSuggestion(suggestion.id);
            if (votes.isEmpty) return const SizedBox.shrink();

            return Column(
              children: [
                _LocationSuggestionVoteSection(
                  title: suggestion.locationName,
                  subtitle: suggestion.address ?? 'address not defined',
                  count: votes.length,
                  votes: votes,
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

/// Vote section for a specific location suggestion (similar to date_time widget format)
class _LocationSuggestionVoteSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;
  final List<SuggestionVote> votes;

  const _LocationSuggestionVoteSection({
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

        // Vote list (sorted by most recent first)
        ...(votes.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
            .map((vote) => _LocationSuggestionVoteItem(vote: vote)),
      ],
    );
  }
}

/// Individual vote item for location suggestions
class _LocationSuggestionVoteItem extends StatelessWidget {
  final SuggestionVote vote;

  const _LocationSuggestionVoteItem({required this.vote});

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
          Text(
            _formatVoteDate(vote.createdAt),
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
      // Show time if voted today (e.g., "10:23")
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
