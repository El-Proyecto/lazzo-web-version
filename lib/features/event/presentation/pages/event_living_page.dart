import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/components/dialogs/add_expense_bottom_sheet.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/event_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/event_photo_providers.dart';
import '../widgets/living_time_left_pill.dart';
import '../widgets/living_action_row.dart';
import '../widgets/chat_preview_widget.dart';
import '../widgets/host_time_controls.dart';
import '../widgets/event_expenses_widget.dart';

/// Helper function to display "You" for current user, otherwise their name
String _getUserDisplayName(
    String userId, String userName, String? currentUserId) {
  return userId == currentUserId ? 'You' : userName;
}

/// Event page for Living mode
/// Displays event in progress with photo upload, chat, and host controls
class EventLivingPage extends ConsumerWidget {
  final String eventId;

  const EventLivingPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final messagesAsync = ref.watch(chatMessagesProvider(eventId));

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
        data: (event) {
          return SingleChildScrollView(
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

                // Time left pill (with controls for host)
                if (event.endDateTime != null)
                  event.hostId == 'current-user' // TODO: Get from auth
                      ? HostTimeControls(
                          eventEndTime: event.endDateTime!,
                          onExtend30Minutes: () {
                            // TODO: Extend event by 30 minutes
                          },
                          onCustomExtend: () {
                            // TODO: Show custom time picker
                          },
                          onEndNow: () {
                            // TODO: End event now
                          },
                        )
                      : LivingTimeLeftPill(
                          eventEndTime: event.endDateTime!,
                        ),
                const SizedBox(height: Gaps.lg),

                // Action row
                LivingActionRow(
                  onAddExpense: () {
                    // Open add expense bottom sheet
                    AddExpenseBottomSheet.show(
                      context: context,
                      participants: [], // TODO: Get event participants
                      onAddExpense: (title, paidByIds, payerIds, amount) async {
                        // TODO: Implement add expense
                      },
                    );
                  },
                  onTakePhoto: () async {
                    // Get photo upload notifier
                    final photoNotifier = ref.read(
                      eventPhotoUploadNotifierProvider(eventId).notifier,
                    );

                    // Take photo and upload
                    await photoNotifier.takePhoto(
                      eventId: eventId,
                      groupId: event.groupId,
                    );

                    // Show result
                    final uploadState = ref.read(
                      eventPhotoUploadNotifierProvider(eventId),
                    );

                    uploadState.when(
                      data: (photoUrl) {
                        if (photoUrl != null) {
                          TopBanner.showSuccess(
                            context,
                            message: '✅ Photo uploaded successfully!',
                          );
                          // Refresh event to update photo count
                          ref.invalidate(eventDetailProvider(eventId));
                        }
                      },
                      loading: () {},
                      error: (error, _) {
                        TopBanner.showError(
                          context,
                          message: '❌ Failed to upload photo: $error',
                        );
                      },
                    );
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
                      currentUserId: currentUserId ?? 'current-user',
                      recentMessages: messages
                          .map(
                            (m) => ChatMessagePreview(
                              userId: m.userId,
                              userName: _getUserDisplayName(
                                  m.userId, m.userName, currentUserId),
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
                      onSendMessage: (content,
                          {ChatMessagePreview? replyTo}) async {
                        // Convert ChatMessagePreview to ChatMessage if replying
                        ChatMessage? replyToMessage;
                        if (replyTo != null && messagesAsync.hasValue) {
                          final messages = messagesAsync.value!;
                          try {
                            replyToMessage = messages.firstWhere(
                              (m) =>
                                  m.userId == replyTo.userId &&
                                  m.content == replyTo.content &&
                                  m.createdAt == replyTo.timestamp,
                            );
                          } catch (_) {
                            // Message not found, ignore reply
                          }
                        }

                        await ref
                            .read(chatActionsProvider(eventId))
                            .sendMessage(content, replyTo: replyToMessage);
                      },
                      mode: ChatMode.living,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: Gaps.lg),

                // Expenses widget
                EventExpensesWidget(
                  eventId: eventId,
                  mode: ChatMode.living,
                  participants: const [], // TODO: Get event participants
                  onAddExpense: (title, paidByIds, payerIds, amount) async {
                    // TODO: Implement add expense
                  },
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading event: $error')),
      ),
    );
  }
}
