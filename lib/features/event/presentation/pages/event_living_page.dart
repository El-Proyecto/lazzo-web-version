import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/components/dialogs/add_expense_bottom_sheet.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../expense/presentation/providers/event_expense_providers.dart';
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
class EventLivingPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventLivingPage({super.key, required this.eventId});

  @override
  ConsumerState<EventLivingPage> createState() => _EventLivingPageState();
}

class _EventLivingPageState extends ConsumerState<EventLivingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInAppBar = false;

  @override
  void initState() {
    super.initState();
    // Setup Realtime subscription for unread count badge updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadCountRealtimeProvider(widget.eventId));
    });
    // Listen to scroll to show/hide title in app bar
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show title when scrolled past ~150px (approximate header height)
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 150;
    if (shouldShow != _showTitleInAppBar) {
      setState(() {
        _showTitleInAppBar = shouldShow;
      });
    }
  }

  Future<void> refreshEventData() async {
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(chatMessagesProvider(widget.eventId));
    ref.invalidate(unreadMessagesCountProvider(widget.eventId));
    ref.invalidate(eventParticipantsProvider(widget.eventId));
    ref.invalidate(eventExpensesProvider(widget.eventId));
    ref.invalidate(eventPhotosProvider(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.eventId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: _showTitleInAppBar ? (eventAsync.value?.name ?? '') : '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: eventAsync.when(
        data: (event) => RefreshIndicator(
          onRefresh: refreshEventData,
          color: BrandColors.living,
          backgroundColor: BrandColors.bg2,
          child: SingleChildScrollView(
            controller: _scrollController,
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
                  event.hostId == currentUserId
                      ? HostTimeControls(
                          eventEndTime: event.endDateTime!,
                          onExtend30Minutes: () async {
                            // Extend event by 30 minutes
                            try {
                              await ref
                                  .read(extendEventTimeProvider)
                                  .call(widget.eventId, 30);
                              // Refresh event details
                              ref.invalidate(
                                  eventDetailProvider(widget.eventId));
                              if (context.mounted) {
                                TopBanner.showSuccess(context,
                                    message: 'Event extended by 30 minutes');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TopBanner.showError(context,
                                    message: 'Failed to extend event: $e');
                              }
                            }
                          },
                          onCustomExtend: (minutes) async {
                            // Extend event by custom minutes
                            try {
                              await ref
                                  .read(extendEventTimeProvider)
                                  .call(widget.eventId, minutes);
                              // Refresh event details
                              ref.invalidate(
                                  eventDetailProvider(widget.eventId));
                              if (context.mounted) {
                                TopBanner.showSuccess(context,
                                    message:
                                        'Event extended by $minutes minutes');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TopBanner.showError(context,
                                    message: 'Failed to extend event: $e');
                              }
                            }
                          },
                          onEndNow: () async {
                            // End event immediately
                            try {
                              await ref
                                  .read(endEventNowProvider)
                                  .call(widget.eventId);
                              // Refresh event details
                              ref.invalidate(
                                  eventDetailProvider(widget.eventId));
                              if (context.mounted) {
                                TopBanner.showSuccess(context,
                                    message: 'Event ended successfully');
                                // Navigate back to group hub or home
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TopBanner.showError(context,
                                    message: 'Failed to end event: $e');
                              }
                            }
                          },
                        )
                      : LivingTimeLeftPill(
                          eventEndTime: event.endDateTime!,
                        ),
                const SizedBox(height: Gaps.lg),

                // Action row
                LivingActionRow(
                  onAddExpense: () async {
                    // Get event participants
                    final participantsAsync = await ref
                        .read(eventParticipantsProvider(widget.eventId).future);

                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;
                    final participants = participantsAsync
                        .map((p) => ExpenseParticipantOption(
                              id: p.userId,
                              name: _getUserDisplayName(
                                p.userId,
                                p.displayName,
                                currentUserId,
                              ),
                              avatarUrl: p.avatarUrl,
                            ))
                        .toList();

                    if (!context.mounted) return;

                    // Open add expense bottom sheet
                    AddExpenseBottomSheet.show(
                      context: context,
                      participants: participants,
                      onAddExpense:
                          (title, paidBy, participantsOwe, amount) async {
                        // Create expense using expense provider
                        try {
                          await ref
                              .read(eventExpensesProvider(widget.eventId)
                                  .notifier)
                              .addExpense(
                            description: title,
                            amount: amount,
                            paidBy: paidBy,
                            participantsOwe: participantsOwe,
                            participantsPaid: [paidBy],
                          );

                          if (context.mounted) {
                            TopBanner.showSuccess(context,
                                message: 'Expense added successfully');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            TopBanner.showError(context,
                                message: 'Failed to add expense: $e');
                          }
                        }
                      },
                    );
                  },
                  onTakePhoto: () async {
                    // Get photo upload notifier
                    final photoNotifier = ref.read(
                      eventPhotoUploadNotifierProvider(widget.eventId).notifier,
                    );

                    // Take photo and upload
                    await photoNotifier.takePhoto(
                      eventId: widget.eventId,
                      groupId: event.groupId,
                    );

                    // Show result
                    final uploadState = ref.read(
                      eventPhotoUploadNotifierProvider(widget.eventId),
                    );

                    uploadState.when(
                      data: (photoUrl) {
                        if (photoUrl != null) {
                          TopBanner.showSuccess(
                            context,
                            message: '✅ Photo uploaded successfully!',
                          );

                          // Optimistic UI: invalidate all photo-related providers
                          // This forces fresh data fetch when navigating to manage memory
                          ref.invalidate(eventDetailProvider(widget.eventId));
                          ref.invalidate(eventPhotosProvider(widget.eventId));

                          // Navigate immediately to manage memory page
                          // The manageMemoryProvider will fetch fresh photos on init
                          if (context.mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRouter.manageMemory,
                              arguments: {
                                'memoryId': widget.eventId,
                              },
                            );
                          }
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
                    // Navigate to manage memory page
                    Navigator.pushNamed(
                      context,
                      AppRouter.manageMemory,
                      arguments: {
                        'memoryId': widget.eventId,
                      },
                    );
                  },
                ),
                const SizedBox(height: Gaps.lg),

                // Chat preview (purple accent)
                messagesAsync.when(
                  data: (messages) {
                    // Get unread count (now returns AsyncValue)
                    final unreadCountAsync = ref.watch(
                      unreadMessagesCountProvider(widget.eventId),
                    );

                    final unreadCount = unreadCountAsync.maybeWhen(
                      data: (count) => count,
                      orElse: () => 0,
                    );

                    return ChatPreviewWidget(
                      newMessagesCount: unreadCount,
                      currentUserId: currentUserId ?? 'unknown',
                      recentMessages: messages
                          .map(
                            (m) => ChatMessagePreview(
                              userId: m.userId,
                              userName: _getUserDisplayName(
                                  m.userId, m.userName, currentUserId),
                              userAvatar: m.userAvatar,
                              content: m.content,
                              timestamp: m.createdAt,
                              isReadBySomeone: m.isReadBySomeone,
                              isReadByEveryone: m.isReadByEveryone,
                              isDeleted: m.isDeleted,
                              isPending: m.isPending,
                            ),
                          )
                          .toList(),
                      onOpenChat: () {
                        // Navigate to event chat page
                        Navigator.pushNamed(
                          context,
                          AppRouter.eventChat,
                          arguments: {'eventId': widget.eventId},
                        );
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
                            .read(chatActionsProvider(widget.eventId))
                            .sendMessage(content, replyTo: replyToMessage);
                      },
                      mode: ChatMode.living,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

                // Expenses widget (spacing will be added after if widget renders)
                FutureBuilder(
                  future: ref
                      .read(eventParticipantsProvider(widget.eventId).future),
                  builder: (context, snapshot) {
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;
                    final participants = snapshot.data
                            ?.map((p) => ExpenseParticipantOption(
                                  id: p.userId,
                                  name: _getUserDisplayName(
                                    p.userId,
                                    p.displayName,
                                    currentUserId,
                                  ),
                                  avatarUrl: p.avatarUrl,
                                ))
                            .toList() ??
                        [];

                    // Check if there are expenses to show
                    final expensesAsync =
                        ref.watch(eventExpensesProvider(widget.eventId));
                    final hasExpenses = expensesAsync.when(
                      data: (expenses) => expenses.isNotEmpty,
                      loading: () => false,
                      error: (_, __) => false,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spacing before expenses section (only if chat exists above)
                        const SizedBox(height: Gaps.lg),
                        EventExpensesWidget(
                          eventId: widget.eventId,
                          mode: ChatMode.living,
                          participants: participants,
                          onAddExpense:
                              (title, paidBy, participantsOwe, amount) async {
                            try {
                              await ref
                                  .read(eventExpensesProvider(widget.eventId)
                                      .notifier)
                                  .addExpense(
                                description: title,
                                amount: amount,
                                paidBy: paidBy,
                                participantsOwe: participantsOwe,
                                participantsPaid: [paidBy],
                              );

                              if (context.mounted) {
                                TopBanner.showSuccess(context,
                                    message: 'Expense added successfully');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TopBanner.showError(context,
                                    message: 'Failed to add expense: $e');
                              }
                            }
                          },
                        ),
                        // Only add spacing after if there are expenses
                        if (hasExpenses) const SizedBox(height: Gaps.lg),
                      ],
                    );
                  },
                ),

                // Location Widget (if location is set)
                if (event.location != null)
                  LocationWidget(
                    displayName: event.location!.displayName,
                    formattedAddress: event.location!.formattedAddress,
                    latitude: event.location!.latitude,
                    longitude: event.location!.longitude,
                  ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading event: $error')),
      ),
    );
  }
}
