import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/pending_event.dart';
import '../providers/pending_event_providers.dart';
import '../../../../shared/components/cards/pending_event_card.dart';
import '../../../../shared/components/cards/pending_event_expanded_card.dart';
import '../../../../shared/components/buttons/simple_vote_button.dart';
import '../../../../shared/components/buttons/voting_button.dart';
import '../../../../shared/components/buttons/voted_no_button.dart';
import '../../../../shared/components/buttons/stacked_avatars.dart';
import '../../../../shared/constants/vote_status.dart';

class PendingEventWidget extends ConsumerWidget {
  final PendingEvent event;

  const PendingEventWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteState = ref.watch(voteStateProvider(event.eventId));
    final voteNotifier = ref.read(voteStateProvider(event.eventId).notifier);

    // Determine the current effective state
    // Use voteState for user interactions, but respect event's initial state
    final effectiveStatus = _getEffectiveStatus(
      voteState.status,
      event.voteStatus,
    );

    // Use expanded card for votersExpanded state
    if (effectiveStatus == VoteStatus.votersExpanded) {
      // Get voters including user's vote if they voted
      final votersWithUser = _getVotersIncludingUser(voteState);
      final yesVoters = votersWithUser
          .where((v) => v.response == 'yes')
          .toList();
      final noVoters = votersWithUser.where((v) => v.response == 'no').toList();

      // Determine user's vote status
      UserVoteStatus userVote = voteState.userVote == true
          ? UserVoteStatus.yes
          : voteState.userVote == false
          ? UserVoteStatus.no
          : UserVoteStatus.notVoted;

      return PendingEventExpandedCard(
        emoji: event.emoji,
        title: event.title,
        dateTime: _formatDateTime(event.scheduledDate),
        location: event.location,
        yesVoters: yesVoters,
        noVoters: noVoters,
        noResponseVoters: event.noResponseVoters,
        noResponseCount: event.noResponseCount,
        userVote: userVote,
        onCollapse: () => voteNotifier.toggleExpansion(),
        onVoteAgain: () => voteNotifier.resetToVoting(),
      );
    }

    // Use regular card for other states
    return PendingEventCard(
      emoji: event.emoji,
      title: event.title,
      dateTime: _formatDateTime(event.scheduledDate),
      location: event.location,
      voteButton: _buildVoteButton(effectiveStatus, voteNotifier, voteState),
    );
  }

  List<VoterInfo> _getVotersIncludingUser(VoteState voteState) {
    final voters = List<VoterInfo>.from(event.voters);

    // Add user's vote if they have voted
    if (voteState.userVote != null) {
      final userVoter = VoterInfo(
        name: 'Você', // Current user
        avatarUrl: 'https://i.pravatar.cc/150?img=50', // User's avatar
        response: voteState.userVote! ? 'yes' : 'no',
        votedAt: DateTime.now(),
      );
      voters.add(userVoter);
    }

    // Sort by most recent first (null votedAt goes to end)
    voters.sort((a, b) {
      if (a.votedAt == null && b.votedAt == null) return 0;
      if (a.votedAt == null) return 1;
      if (b.votedAt == null) return -1;
      return b.votedAt!.compareTo(a.votedAt!);
    });

    return voters;
  }

  VoteStatus _getEffectiveStatus(
    VoteStatus voteStateStatus,
    VoteStatus eventStatus,
  ) {
    // If vote state has been modified by user interaction, use it
    if (voteStateStatus == VoteStatus.votersExpanded) {
      return VoteStatus.votersExpanded;
    }
    // If vote state is voting or if user has made new vote, use vote state
    if (voteStateStatus == VoteStatus.voting ||
        voteStateStatus == VoteStatus.voted) {
      return voteStateStatus;
    }
    // Otherwise use the event's initial state
    return eventStatus;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM, HH:mm').format(dateTime);
  }

  Widget _buildVoteButton(
    VoteStatus status,
    VoteStateNotifier notifier,
    VoteState voteState,
  ) {
    switch (status) {
      case VoteStatus.vote:
        // Initial state - show stacked avatars if there are existing voters, otherwise simple vote button
        final yesVoters = event.voters
            .where((v) => v.response == 'yes')
            .toList();
        if (yesVoters.isNotEmpty) {
          return StackedAvatars(
            voters: yesVoters,
            onTap: () => notifier.toggleExpansion(),
          );
        }
        return SimpleVoteButton(onTap: () => notifier.startVoting());

      case VoteStatus.voting:
        // Voting state - show yes/no buttons
        return VotingButton(
          onYes: () => notifier.vote(true),
          onNo: () => notifier.vote(false),
        );

      case VoteStatus.voted:
        // Voted state - show appropriate button based on vote
        if (voteState.userVote == true) {
          // User voted yes - show stacked avatars with all yes voters
          final votersWithUser = _getVotersIncludingUser(voteState);
          final yesVoters = votersWithUser
              .where((v) => v.response == 'yes')
              .toList();
          return StackedAvatars(
            voters: yesVoters,
            onTap: () => notifier.toggleExpansion(),
          );
        } else if (voteState.userVote == false) {
          // User voted no - only show expand button if there are no yes voters
          final votersWithUser = _getVotersIncludingUser(voteState);
          final yesVoters = votersWithUser
              .where((v) => v.response == 'yes')
              .toList();

          if (yesVoters.isEmpty) {
            print('No yes voters, showing VotedNoButton');
            // No yes voters - show expand button to see results
            return VotedNoButton(onTap: () => notifier.toggleExpansion());
          } else {
            // There are yes voters - show their stacked avatars
            print('yesVoters: $yesVoters');
            return StackedAvatars(
              voters: yesVoters,
              onTap: () => notifier.toggleExpansion(),
            );
          }
        }
        print('User has not voted, showing SimpleVoteButton');
        // If user hasn't voted yet, show simple vote button
        return SimpleVoteButton(onTap: () => notifier.startVoting());

      case VoteStatus.votersExpanded:
        // This shouldn't happen in regular card, but fallback to stacked avatars
        final votersWithUser = _getVotersIncludingUser(voteState);
        final yesVoters = votersWithUser
            .where((v) => v.response == 'yes')
            .toList();
        return StackedAvatars(
          voters: yesVoters,
          onTap: () => notifier.toggleExpansion(),
        );
    }
  }
}
