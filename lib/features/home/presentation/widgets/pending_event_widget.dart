// TODO P2: Remove this file - replaced by new home structure with EventSmallCard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/pending_event.dart';
import '../providers/pending_event_providers.dart';
import '../../../../shared/components/cards/pending_event_card.dart';
import '../../../../shared/components/cards/pending_event_expanded_card.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'simple_vote_button.dart';
import 'voting_button.dart';
import 'voted_no_button.dart';
import '../../../../shared/components/buttons/stacked_avatars.dart';
import '../../../../shared/constants/vote_status.dart';

class PendingEventWidget extends ConsumerWidget {
  final PendingEvent event;

  const PendingEventWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteState = ref.watch(voteStateProvider(event.eventId));
    final voteNotifier = ref.read(voteStateProvider(event.eventId).notifier);

    final authState = ref.watch(authProvider);
    final currentUser = authState.valueOrNull;

    final effectiveStatus = _getEffectiveStatus(
      voteState.status,
      event.userVote,
    );

    if (effectiveStatus == VoteStatus.votersExpanded) {
      final yesVoters =
          _replaceCurrentUserName(event.goingUsers, currentUser?.id);
      final noVoters =
          _replaceCurrentUserName(event.notGoingUsers, currentUser?.id);
      final noResponseVoters =
          _replaceCurrentUserName(event.noResponseUsers, currentUser?.id);

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
        noResponseVoters: noResponseVoters,
        noResponseCount: event.noResponseTotal,
        userVote: userVote,
        onCollapse: () => voteNotifier.toggleExpansion(),
        onVoteAgain: () => voteNotifier.resetToVoting(),
        onTap: () => _navigateToEventDetail(context),
      );
    }

    return PendingEventCard(
      emoji: event.emoji,
      title: event.title,
      dateTime: _formatDateTime(event.scheduledDate),
      location: event.location,
      voteButton: _buildVoteButton(
        effectiveStatus,
        voteNotifier,
        voteState,
        currentUser?.id,
      ),
      onTap: () => _navigateToEventDetail(context),
    );
  }

  void _navigateToEventDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRouter.event,
      arguments: {'eventId': event.eventId},
    );
  }

  List<VoterInfo> _replaceCurrentUserName(
    List<VoterInfo> voters,
    String? currentUserId,
  ) {
    if (currentUserId == null) return voters;

    return voters.map((voter) {
      if (voter.id == currentUserId) {
        return VoterInfo(
          id: voter.id,
          name: 'You',
          avatarUrl: voter.avatarUrl,
          votedAt: voter.votedAt,
        );
      }
      return voter;
    }).toList();
  }

  // ✅ SIMPLIFICADO: usa bool? em vez de VoteStatus
  VoteStatus _getEffectiveStatus(
    VoteStatus voteStateStatus,
    bool? eventUserVote,
  ) {
    // Prioriza estados de UI transitórios
    if (voteStateStatus == VoteStatus.votersExpanded) {
      return VoteStatus.votersExpanded;
    }
    if (voteStateStatus == VoteStatus.voting) {
      return VoteStatus.voting;
    }
    if (voteStateStatus == VoteStatus.voted) {
      return VoteStatus.voted;
    }

    // Fallback: usa dados do backend
    return eventUserVote == null ? VoteStatus.vote : VoteStatus.voted;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM, HH:mm').format(dateTime);
  }

  Widget _buildVoteButton(
    VoteStatus status,
    VoteStateNotifier notifier,
    VoteState voteState,
    String? currentUserId,
  ) {
    switch (status) {
      case VoteStatus.vote:
        final yesVoters =
            _replaceCurrentUserName(event.goingUsers, currentUserId);

        if (yesVoters.isNotEmpty) {
          return StackedAvatars(
            voters: yesVoters,
            onTap: () => notifier.toggleExpansion(),
          );
        }
        return SimpleVoteButton(onTap: () => notifier.startVoting());

      case VoteStatus.voting:
        return VotingButton(
          onYes: () => notifier.vote(true),
          onNo: () => notifier.vote(false),
        );

      case VoteStatus.voted:
        if (voteState.userVote == true) {
          final yesVoters =
              _replaceCurrentUserName(event.goingUsers, currentUserId);
          return StackedAvatars(
            voters: yesVoters,
            onTap: () => notifier.toggleExpansion(),
          );
        } else if (voteState.userVote == false) {
          final yesVoters =
              _replaceCurrentUserName(event.goingUsers, currentUserId);
          if (yesVoters.isEmpty) {
            return VotedNoButton(onTap: () => notifier.toggleExpansion());
          } else {
            return StackedAvatars(
              voters: yesVoters,
              onTap: () => notifier.toggleExpansion(),
            );
          }
        }
        return SimpleVoteButton(onTap: () => notifier.startVoting());

      case VoteStatus.votersExpanded:
        final yesVoters =
            _replaceCurrentUserName(event.goingUsers, currentUserId);
        return StackedAvatars(
          voters: yesVoters,
          onTap: () => notifier.toggleExpansion(),
        );
    }
  }
}
