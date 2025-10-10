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
  final Function(LocationSuggestion selectedSuggestion)
  onPickLocation; // Callback for pick location
  final String? currentEventLocationName; // Current event location name
  final String? currentEventAddress; // Current event address

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
        _selectedSuggestionId = _selectedSuggestionId == suggestionId
            ? null
            : suggestionId;
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
    if (widget.currentEventLocationName == null &&
        widget.currentEventAddress == null) {
      return false;
    }

    // Compare location name
    if (suggestion.locationName != widget.currentEventLocationName) {
      return false;
    }

    // Compare address
    if (suggestion.address != widget.currentEventAddress) {
      return false;
    }

    return true;
  }

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
              // Only show view votes if there are any votes
              if (widget.suggestions.any((s) => _getVoteCount(s.id) > 0)) ...[
                InkWell(
                  onTap: () => _showViewVotesBottomSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
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
                        'Pick Location',
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

    return AnimatedScale(
      scale: hasUserVoted ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: isCurrentEvent ? null : () => _handleVote(suggestion.id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
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
            border: _isSelectionMode
                ? (isSelected
                      ? Border.all(color: BrandColors.planning, width: 1)
                      : null)
                : isCurrentEvent
                ? null
                : hasUserVoted
                ? Border.all(color: BrandColors.planning, width: 1)
                : null,
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
                        color: isSelected ? Colors.white : Colors.transparent,
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
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
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
                            ? (isSelected ? FontWeight.w600 : FontWeight.normal)
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
                      suggestion.address ?? 'endereço não definido',
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
                  color: _isSelectionMode
                      ? (isSelected ? BrandColors.planning : BrandColors.border)
                      : isCurrentEvent
                      ? BrandColors.border
                      : hasUserVoted
                      ? BrandColors.planning
                      : BrandColors.border,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showViewVotesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Radii.md),
            topRight: Radius.circular(Radii.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with grabber
            const SizedBox(height: Gaps.sm),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: BrandColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Gaps.md),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
              child: Text(
                'Location Votes',
                style: AppText.labelLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: Gaps.sm),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Pads.ctlH),
                decoration: BoxDecoration(
                  color: BrandColors.bg3,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  'See who voted for each location suggestion.',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              ),
            ),
            const SizedBox(height: Gaps.md),

            // Votes list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
                itemCount: widget.suggestions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: Gaps.md),
                itemBuilder: (context, index) {
                  final suggestion = widget.suggestions[index];
                  return _buildVoteCard(suggestion);
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + Gaps.md),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteCard(LocationSuggestion suggestion) {
    final votes = _getVotesForSuggestion(suggestion.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.ctlH),
      decoration: BoxDecoration(
        color: BrandColors.bg1,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.locationName,
                      style: AppText.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (suggestion.address != null) ...[
                      const SizedBox(height: Gaps.xxs),
                      Text(
                        suggestion.address!,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gaps.xs,
                  vertical: Gaps.xxs,
                ),
                decoration: BoxDecoration(
                  color: BrandColors.planning,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  '${_getVoteCount(suggestion.id)}',
                  style: AppText.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (votes.isNotEmpty) ...[
            const SizedBox(height: Gaps.sm),
            const Divider(color: BrandColors.border),
            const SizedBox(height: Gaps.sm),

            // Voters list
            ...votes.map(
              (vote) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.xs),
                child: Row(
                  children: [
                    // Avatar placeholder
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: BrandColors.bg3,
                      child: vote.userAvatar != null
                          ? ClipOval(
                              child: Image.network(
                                vote.userAvatar!,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 14,
                              color: BrandColors.text2,
                            ),
                    ),
                    const SizedBox(width: Gaps.xs),
                    Expanded(
                      child: Text(
                        vote.userName,
                        style: AppText.bodyMedium.copyWith(fontSize: 12),
                      ),
                    ),
                    Text(
                      _formatVoteTime(vote.createdAt),
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatVoteTime(DateTime voteTime) {
    final now = DateTime.now();
    final difference = now.difference(voteTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
