import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/widgets/rsvp_widget.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/components/widgets/date_time_widget.dart';
import '../../../../shared/components/widgets/poll_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/rsvp.dart';
import '../providers/event_providers.dart';
import '../widgets/chat_preview_widget.dart';

/// Event detail page
/// Displays all event information and interactions
class EventPage extends ConsumerWidget {
  final String eventId;

  const EventPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
    final userRsvpAsync = ref.watch(userRsvpProvider(eventId));
    final pollsAsync = ref.watch(eventPollsProvider(eventId));
    final messagesAsync = ref.watch(recentMessagesProvider(eventId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: BrandColors.text1),
          onPressed: () {
            // TODO: Navigate to edit event page
          },
        ),
      ),
      body: eventAsync.when(
        data: (event) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.screenH,
            vertical: Gaps.lg,
          ),
          child: Column(
            children: [
              // Event header
              EventHeader(
                emoji: event.emoji,
                title: event.name,
                location: event.location?.displayName,
                dateTime: event.startDateTime,
              ),
              const SizedBox(height: Gaps.xl),

              // RSVP Widget
              userRsvpAsync.when(
                data: (userRsvp) => RsvpWidget(
                  goingCount: event.goingCount,
                  notGoingCount: event.notGoingCount,
                  userVote: _getUserVoteStatus(userRsvp),
                  onGoingPressed: () {
                    ref
                        .read(userRsvpProvider(eventId).notifier)
                        .submitVote(RsvpStatus.going);
                  },
                  onNotGoingPressed: () {
                    ref
                        .read(userRsvpProvider(eventId).notifier)
                        .submitVote(RsvpStatus.notGoing);
                  },
                  onViewVotesPressed: () {
                    _showRsvpList(context, rsvpsAsync);
                  },
                  onAddSuggestionPressed: _getUserVoteStatus(userRsvp) == false
                      ? () => _showAddSuggestionDialog(context, ref)
                      : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: Gaps.xl),

              // Chat Preview
              messagesAsync.when(
                data: (messages) => ChatPreviewWidget(
                  recentMessages: messages
                      .map(
                        (m) => ChatMessagePreview(
                          userName: m.userName,
                          content: m.content,
                          timestamp: m.createdAt,
                        ),
                      )
                      .toList(),
                  onOpenChat: () {
                    // TODO: Navigate to full chat page
                  },
                  onSendMessage: (content) {
                    ref
                        .read(sendMessageProvider.notifier)
                        .sendMessage(eventId, content);
                    // Refresh messages
                    ref.invalidate(recentMessagesProvider(eventId));
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: Gaps.xl),

              // Location Widget (if location is set)
              if (event.location != null) ...[
                LocationWidget(
                  displayName: event.location!.displayName,
                  formattedAddress: event.location!.formattedAddress,
                  latitude: event.location!.latitude,
                  longitude: event.location!.longitude,
                ),
                const SizedBox(height: Gaps.xl),
              ],

              // Date & Time Widget (if date is set)
              if (event.startDateTime != null) ...[
                DateTimeWidget(
                  eventName: event.name,
                  startDateTime: event.startDateTime!,
                  endDateTime: event.endDateTime,
                  location: event.location?.formattedAddress,
                ),
                const SizedBox(height: Gaps.xl),
              ],

              // Polls (if no date/location or if there are suggestions)
              pollsAsync.when(
                data: (polls) {
                  if (polls.isEmpty &&
                      (event.startDateTime == null || event.location == null)) {
                    // Show empty state for polls
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: polls.map((poll) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Gaps.xl),
                        child: PollWidget(
                          question: poll.question,
                          options: poll.options
                              .map(
                                (opt) => PollOptionData(
                                  id: opt.id,
                                  label: opt.value,
                                  voteCount: opt.voteCount,
                                ),
                              )
                              .toList(),
                          userVotedOptionId: _getUserVotedOption(poll),
                          isHost: event.hostId == 'current-user',
                          onVote: (optionId) {
                            // TODO: Implement vote on poll
                          },
                          onPickFinal: event.hostId == 'current-user'
                              ? (optionId) {
                                  // TODO: Implement pick final option
                                }
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Erro ao carregar evento: $error')),
      ),
    );
  }

  bool? _getUserVoteStatus(Rsvp? rsvp) {
    if (rsvp == null || rsvp.status == RsvpStatus.pending) return null;
    return rsvp.status == RsvpStatus.going;
  }

  String? _getUserVotedOption(dynamic poll) {
    // TODO: Implement logic to check if current user voted
    return null;
  }

  void _showRsvpList(BuildContext context, AsyncValue rsvpsAsync) {
    rsvpsAsync.whenData((rsvps) {
      showModalBottomSheet(
        context: context,
        backgroundColor: BrandColors.bg2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(Pads.sectionH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.md),
              ...rsvps
                  .where((r) => r.status == RsvpStatus.going)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: Gaps.sm),
                      child: Text(
                        r.userName,
                        style: const TextStyle(color: BrandColors.text1),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    });
  }

  void _showAddSuggestionDialog(BuildContext context, WidgetRef ref) {
    // TODO: Implement add suggestion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.bg2,
        title: const Text(
          'Adicionar sugestão',
          style: TextStyle(color: BrandColors.text1),
        ),
        content: const Text(
          'Funcionalidade em desenvolvimento',
          style: TextStyle(color: BrandColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
