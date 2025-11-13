import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/event_providers.dart';
import '../widgets/living_time_left_pill.dart';
import '../widgets/living_action_row.dart';
import '../widgets/chat_preview_widget.dart';

/// Event page for Living mode
/// Displays event in progress with photo upload, chat, and host controls
class EventLivingPage extends ConsumerWidget {
  final String eventId;

  const EventLivingPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final messagesAsync = ref.watch(recentMessagesProvider(eventId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
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
                endDateTime: event.endDateTime,
              ),
              const SizedBox(height: Gaps.md),

              // Time left pill
              if (event.endDateTime != null)
                LivingTimeLeftPill(
                  eventEndTime: event.endDateTime!,
                ),
              const SizedBox(height: Gaps.lg),

              // Action row
              LivingActionRow(
                onAddExpense: () {
                  // TODO: Navigate to add expense
                },
                onTakePhoto: () {
                  // TODO: Open camera
                },
                onViewMemory: () {
                  // TODO: Navigate to memory
                },
              ),
              const SizedBox(height: Gaps.lg),

              // Chat preview (purple accent)
              messagesAsync.when(
                data: (messages) {
                  final unreadCount = ref.watch(
                    unreadMessagesCountProvider(eventId),
                  );
                  return ChatPreviewWidget(
                    newMessagesCount: unreadCount,
                    currentUserId:
                        'current-user', // TODO: Get from auth provider
                    recentMessages: messages
                        .map(
                          (m) => ChatMessagePreview(
                            userId: m.userId,
                            userName: m.userName,
                            userAvatar: m.userAvatar,
                            content: m.content,
                            timestamp: m.createdAt,
                            read: m.read,
                          ),
                        )
                        .toList(),
                    onOpenChat: () {
                      // TODO: Navigate to chat
                    },
                    onSendMessage: (content) async {
                      await ref
                          .read(sendMessageProvider.notifier)
                          .sendMessage(eventId, content);
                    },
                    mode: ChatMode.living,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: Gaps.lg),

              // Location Widget (if location is set)
              if (event.location != null) ...[
                LocationWidget(
                  displayName: event.location!.displayName,
                  formattedAddress: event.location!.formattedAddress,
                  latitude: event.location!.latitude,
                  longitude: event.location!.longitude,
                ),
                const SizedBox(height: Gaps.lg),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading event: $error')),
      ),
    );
  }
}
