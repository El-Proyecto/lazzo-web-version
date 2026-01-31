import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/dialogs/add_expense_bottom_sheet.dart';
import '../../../../shared/components/dialogs/message_actions_sheet.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/widgets/chat_messages_list.dart';
import '../../../../shared/components/widgets/message_suggestions.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../providers/event_providers.dart';
import '../../../expense/presentation/providers/event_expense_providers.dart';
import '../../domain/entities/event_detail.dart';

/// Event chat page
/// Full-screen chat interface for event communication
class EventChatPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventChatPage({super.key, required this.eventId});

  @override
  ConsumerState<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends ConsumerState<EventChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, GlobalKey> _messageKeys = {};
  bool _notificationsMuted = false;
  bool _showBanner = false;
  bool _isUserScrolling = false;
  bool _shouldAutoScroll = true;
  ChatMessage? _replyingTo;
  String? _scrollToMessageId;

  // Track if we should mark as read on dispose
  bool _shouldMarkAsReadOnDispose = false;
  bool _isDisposing = false;

  // Optimistic UI: pending messages waiting to be confirmed
  final List<ChatMessage> _pendingMessages = [];

  // Infinite scroll state
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  final List<ChatMessage> _olderMessages = [];

  // ✅ NEW: Chat active presence tracking
  Timer? _heartbeatTimer;

  /// Get current user ID from Supabase auth
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  /// Get current event state color based on event status
  Color _getEventStateColor(EventStatus? status) {
    switch (status) {
      case EventStatus.living:
        return BrandColors.living; // Purple
      case EventStatus.recap:
        return BrandColors.recap; // Orange
      case EventStatus.pending:
      case EventStatus.confirmed:
      default:
        return BrandColors.planning; // Green
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ NEW: Add lifecycle observer for app state changes
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);

    // Mark that we should update read status when leaving
    _shouldMarkAsReadOnDispose = true;

    // ✅ NEW: Register user as active in this chat
    _registerChatActive();
    _startHeartbeat();

    // Refresh chat messages when entering the page to ensure latest messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Invalidate the chat provider to force a fresh fetch
      ref.invalidate(chatMessagesProvider(widget.eventId));

      // Also refresh unread count
      ref.invalidate(unreadMessagesCountProvider(widget.eventId));

      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('scrollToMessageId')) {
        setState(() {
          _scrollToMessageId = args['scrollToMessageId'] as String?;
        });
      }

      // Note: Messages are marked as read on dispose (when leaving page)
      // or when user sends a message
    });
  }

  @override
  void deactivate() {
    // Mark messages as read when leaving the page
    // Use deactivate instead of dispose because ref is still available here
    if (_shouldMarkAsReadOnDispose && !_isDisposing) {
      _markMessagesAsRead();
      _shouldMarkAsReadOnDispose = false; // Only mark once
    }

    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposing = true;

    // ✅ Stop heartbeat (presence expires automatically via server timeout)
    _heartbeatTimer?.cancel();
    // NOTE: We intentionally do NOT call _unregisterChatActive() here.
    // For multi-device safety, presence expires via 30s server timeout.
    // This prevents issues where leaving chat on one device logs out all devices.

    // ✅ Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _scrollController.removeListener(_onScroll);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// ✅ Handle app lifecycle state changes (foreground/background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background → stop heartbeat (presence expires via 30s timeout)
      // NOTE: We do NOT unregister for multi-device safety
      _heartbeatTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground → re-register as active
      _registerChatActive();
      _startHeartbeat();
    }
  }

  /// ✅ Register user as actively viewing this chat using server-side RPC
  /// Prevents receiving push notifications for messages in this chat
  Future<void> _registerChatActive() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Use RPC for server-side timestamp (more reliable than client-side)
      await Supabase.instance.client.rpc(
        'touch_chat_presence',
        params: {'p_event_id': widget.eventId},
      );
    } catch (e) {
      // Silently fail - don't block chat functionality
      // User will receive notifications as fallback (graceful degradation)
    }
  }

  // NOTE: _unregisterChatActive() removed for multi-device safety.
  // Presence expires automatically via 30s server-side timeout.
  // leave_chat_presence RPC exists server-side but is not called from Flutter.

  /// ✅ Start periodic heartbeat to keep "active" status updated
  /// Updates last_seen every 10 seconds to signal user is still viewing chat
  /// (Server uses 30s window, so 10s heartbeat gives 3x safety margin)
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _registerChatActive(); // Update last_seen timestamp via RPC
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final atBottom = _scrollController.offset <= 100;
      if (!atBottom && !_isUserScrolling) {
        setState(() {
          _isUserScrolling = true;
          _shouldAutoScroll = false;
        });
      } else if (atBottom && _isUserScrolling) {
        setState(() {
          _isUserScrolling = false;
          _shouldAutoScroll = true;
        });
      }

      // Infinite scroll: detect when user scrolls to the top (oldest messages)
      // In a reversed ListView, "max scroll extent" is the top (oldest messages)
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final threshold = 200.0; // pixels from top to trigger load

      if (maxScroll - currentScroll <= threshold &&
          !_isLoadingMore &&
          _hasMoreMessages) {
        _loadMoreMessages();
      }
    }
  }

  /// Load older messages for infinite scroll
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Get the oldest message timestamp from current messages
      final messagesAsync = ref.read(chatMessagesProvider(widget.eventId));
      final currentMessages = messagesAsync.valueOrNull ?? [];

      // Combine stream messages with already loaded older messages
      final allMessages = [...currentMessages, ..._olderMessages];

      if (allMessages.isEmpty) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreMessages = false;
        });
        return;
      }

      // Find the oldest message (last in the combined list since sorted DESC)
      final oldestMessage = allMessages.reduce(
        (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
      );

      // Fetch older messages
      final repository = ref.read(chatRepositoryProvider);
      final olderMessages = await repository.fetchOlderMessages(
        eventId: widget.eventId,
        olderThan: oldestMessage.createdAt,
        limit: 30,
      );

      setState(() {
        _isLoadingMore = false;
        if (olderMessages.isEmpty) {
          _hasMoreMessages = false;
        } else {
          // Filter out duplicates
          final existingIds = allMessages.map((m) => m.id).toSet();
          final newMessages =
              olderMessages.where((m) => !existingIds.contains(m.id)).toList();
          _olderMessages.addAll(newMessages);
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_shouldAutoScroll) {
      setState(() {
        _shouldAutoScroll = true;
      });
    }
  }

  /// Mark all visible messages as read when page opens
  /// This updates the last_read_message_id for the current user
  Future<void> _markMessagesAsRead() async {
    if (_isDisposing) {
      return;
    }

    try {
      // Get latest messages from stream
      final messagesAsync = ref.read(chatMessagesProvider(widget.eventId));

      // Only proceed if we have messages
      await messagesAsync.when(
        data: (messages) async {
          if (messages.isEmpty) {
            return;
          }

          // Get the most recent message (first in list, since sorted DESC)
          final latestMessage = messages.first;

          // Call repository method to update last read message
          final repository = ref.read(chatRepositoryProvider);
          final success = await repository.updateLastReadMessage(
            eventId: widget.eventId,
            messageId: latestMessage.id,
          );

          if (success) {
          } else {}
        },
        loading: () {},
        error: (error, stack) {
          // Error already handled in AsyncValue
        },
      );
    } catch (e) {
      // Silently ignore scroll errors - non-critical UI operation
    }
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsMuted = !_notificationsMuted;
      // Do not use the AppBar banner anymore; show TopBanner instead
      _showBanner = false;
    });

    HapticFeedback.lightImpact();

    // Show TopBanner to notify user about mute/unmute action
    if (mounted) {
      TopBanner.showInfo(
        context,
        message: _notificationsMuted
            ? 'Chat message notifications muted'
            : 'Chat message notifications enabled',
      );
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      // Mark all previous messages as read when user sends a message
      _markMessagesAsRead();

      // Don't mark again on dispose since we just marked
      _shouldMarkAsReadOnDispose = false;

      // Create optimistic pending message
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final pendingMessage = ChatMessage(
          id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
          eventId: widget.eventId,
          userId: currentUser.id,
          userName: currentUser.userMetadata?['username'] ?? 'You',
          userAvatar: currentUser.userMetadata?['avatar_url'],
          content: content,
          createdAt: DateTime.now(),
          isPending: true,
          replyTo: _replyingTo,
        );

        setState(() {
          _pendingMessages.add(pendingMessage);
        });
      }

      _messageController.clear();
      final replyToMessage = _replyingTo;
      setState(() {
        _replyingTo = null;
      });

      if (_shouldAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }

      // Send message to server
      try {
        await ref.read(chatActionsProvider(widget.eventId)).sendMessage(
              content,
              replyTo: replyToMessage,
            );

        // Pending message will be automatically removed when real message arrives
        // (filtered in the build method when matching content is found in stream)
      } catch (e) {
        // Keep pending message visible so user knows it failed
        // Could show a retry button here
      }
    }
  }

  void _onMessageLongPress(ChatMessage message) {
    HapticFeedback.mediumImpact();
    _showMessageMenu(message);
  }

  void _showMessageMenu(ChatMessage message) {
    final isCurrentUser = message.userId == _currentUserId;

    // Store initial focus state
    final hadFocus = _focusNode.hasFocus;

    // Unfocus before showing modal
    if (hadFocus) {
      FocusScope.of(context).unfocus();
    }

    MessageActionsSheet.show(
      context: context,
      messageTimestamp: message.createdAt,
      isPinned: message.isPinned,
      showDelete: isCurrentUser,
      onPin: () => _togglePin(message),
      onReply: () => _replyToMessage(message),
      onDelete: isCurrentUser ? () => _deleteMessage(message) : null,
    ).whenComplete(() {
      // Ensure keyboard stays closed when modal is dismissed without action
      Future.delayed(const Duration(milliseconds: 0), () {
        if (mounted && _replyingTo == null) {
          FocusScope.of(context).unfocus();
        }
      });
    });
  }

  void _togglePin(ChatMessage message) {
    FocusScope.of(context).unfocus();

    ref.read(chatActionsProvider(widget.eventId)).togglePin(
          message.id,
          !message.isPinned,
        );
    HapticFeedback.lightImpact();
  }

  void _replyToMessage(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });

    // Request focus after frame to ensure keyboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _deleteMessage(ChatMessage message) {
    FocusScope.of(context).unfocus();

    ref.read(chatActionsProvider(widget.eventId)).deleteMessage(message.id);
    HapticFeedback.mediumImpact();
  }

  void _scrollToMessage(ChatMessage message) {
    if (!_scrollController.hasClients) return;

    // Get all messages to find the index
    final messagesAsync = ref.read(chatMessagesProvider(widget.eventId));
    messagesAsync.whenData((messages) {
      final messageIndex = messages.indexWhere((m) => m.id == message.id);
      if (messageIndex == -1) return;

      // Average message height (estimate): ~80px for bubble + padding + potential date separator
      const double estimatedMessageHeight = 80.0;
      const double dateIntervalHeight = 50.0; // Date separator

      // Calculate estimated scroll position
      // List is reversed, so index 0 is at bottom (offset 0)
      // We need to scroll from bottom to top
      double estimatedPosition = messageIndex * estimatedMessageHeight;

      // Add extra height for date separators (rough estimate: one every 5 messages)
      estimatedPosition += (messageIndex / 5).floor() * dateIntervalHeight;

      // Get max scroll extent
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Clamp position to valid range
      final targetPosition = estimatedPosition.clamp(0.0, maxScroll);

      // Animate to estimated position first (fast scroll)
      _scrollController
          .animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      )
          .then((_) {
        // After reaching estimated position, use ensureVisible for fine-tuning
        if (!mounted) return;
        _attemptScrollToMessage(message, attempts: 0, maxAttempts: 8);
      });
    });

    HapticFeedback.lightImpact();
  }

  void _attemptScrollToMessage(
    ChatMessage message, {
    required int attempts,
    required int maxAttempts,
  }) {
    if (!mounted || attempts >= maxAttempts) return;

    final messageKey = _messageKeys[message.id];
    final context = messageKey?.currentContext;

    if (context != null && context.mounted) {
      // Fine-tune scroll position to exact message location
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.3,
      );
    } else {
      // Context not ready yet, try again
      final delay = Duration(milliseconds: 50 + (attempts * 30));
      Future.delayed(delay, () {
        _attemptScrollToMessage(
          message,
          attempts: attempts + 1,
          maxAttempts: maxAttempts,
        );
      });
    }
  }

  String _formatSubtitle(DateTime? dateTime, String? location) {
    final parts = <String>[];

    if (location != null && location.isNotEmpty) {
      parts.add(location);
    }

    if (dateTime != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDate = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      );

      String dateString;
      if (eventDate == today) {
        dateString = 'Today';
      } else if (eventDate == today.add(const Duration(days: 1))) {
        dateString = 'Tomorrow';
      } else {
        dateString = '${dateTime.day}/${dateTime.month}';
      }

      final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';

      parts.add('$dateString, $timeString');
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    // Auto-scroll to message if scrollToMessageId is set
    messagesAsync.whenData((messages) {
      if (_scrollToMessageId != null) {
        // Find message by actual ID or generated ID (userId_timestamp)
        final targetMessage = messages.cast<ChatMessage?>().firstWhere(
          (m) {
            if (m == null) return false;
            // Check both actual ID and generated ID format
            final messageId =
                '${m.userId}_${m.createdAt.millisecondsSinceEpoch}';
            return m.id == _scrollToMessageId ||
                messageId == _scrollToMessageId;
          },
          orElse: () => null,
        );

        if (targetMessage != null) {
          // Scroll after messages are rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToMessage(targetMessage);
              // Clear after scrolling
              setState(() {
                _scrollToMessageId = null;
              });
            }
          });
        }
      }
    });

    // Use firstWhereOrNull from collection package for nullable result
    final pinnedMessage = messagesAsync.maybeWhen(
      data: (messages) {
        final pinned = messages.where((m) => m.isPinned).toList();
        return pinned.isNotEmpty ? pinned.first : null;
      },
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: eventAsync.when(
        data: (event) => _ChatAppBar(
          title: event.name,
          subtitle:
              _formatSubtitle(event.startDateTime, event.location?.displayName),
          onBackPressed: () {
            Navigator.of(context).pop();
          },
          notificationsMuted: _notificationsMuted,
          showBanner: _showBanner,
          onToggleNotifications: _toggleNotifications,
          pinnedMessage: pinnedMessage,
          onPinnedMessageTap: pinnedMessage != null
              ? () => _scrollToMessage(pinnedMessage)
              : null,
        ),
        loading: () => _ChatAppBar(
          title: '',
          onBackPressed: () {
            Navigator.of(context).pop();
          },
          notificationsMuted: _notificationsMuted,
          showBanner: false,
          onToggleNotifications: () {},
        ),
        error: (_, __) => _ChatAppBar(
          title: 'Chat',
          onBackPressed: () {
            Navigator.of(context).pop();
          },
          notificationsMuted: _notificationsMuted,
          showBanner: false,
          onToggleNotifications: () {},
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: eventAsync.when(
              data: (event) {
                return messagesAsync.when(
                  data: (messages) {
                    // Filter out pending messages that already exist in real messages
                    // Match by content, userId, and approximate timestamp (within 5 seconds)
                    final filteredPendingMessages =
                        _pendingMessages.where((pending) {
                      final hasDuplicate = messages.any((real) =>
                          real.content == pending.content &&
                          real.userId == pending.userId &&
                          real.createdAt
                                  .difference(pending.createdAt)
                                  .abs()
                                  .inSeconds <
                              5);

                      if (hasDuplicate) {
                        // Remove from pending list in next frame to avoid setState during build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _pendingMessages.removeWhere((p) =>
                                  p.content == pending.content &&
                                  p.userId == pending.userId);
                            });
                          }
                        });
                      }

                      return !hasDuplicate;
                    }).toList();

                    // Combine filtered pending messages with real messages and older loaded messages
                    final allMessages = [
                      ...filteredPendingMessages,
                      ...messages,
                      ..._olderMessages,
                    ];

                    if (allMessages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 64,
                              color: BrandColors.text2.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: Gaps.sm),
                            Text(
                              'No messages yet.',
                              style: AppText.bodyMedium.copyWith(
                                color: BrandColors.text2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Get unread count from new read receipts system
                    final unreadCountAsync = ref.watch(
                      unreadMessagesCountProvider(widget.eventId),
                    );

                    final unreadCount = unreadCountAsync.when(
                      data: (count) {
                        return count;
                      },
                      loading: () => 0,
                      error: (e, stack) {
                        return 0;
                      },
                    );

                    // Build list with date separators and unread indicator
                    final bubbleColor = _getEventStateColor(event.status);
                    return Stack(
                      children: [
                        ChatMessagesList(
                          messages: allMessages,
                          scrollController: _scrollController,
                          onMessageLongPress: _onMessageLongPress,
                          onMessageTap: _scrollToMessage,
                          onSwipeReply: _replyToMessage,
                          messageKeys: _messageKeys,
                          currentUserId: _currentUserId,
                          bubbleColor: bubbleColor,
                          unreadCount: unreadCount,
                          enableSwipeToReply: true,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Pads.sectionH,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                        ),
                        // Loading indicator for infinite scroll
                        if (_isLoadingMore)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(Gaps.sm),
                              color: BrandColors.bg1.withValues(alpha: 0.8),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: BrandColors.text2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // "No more messages" indicator removed - cleaner UX
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Error loading messages',
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => Center(
                child: Text(
                  'Error loading event',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
              ),
            ),
          ),

          // Message input
          eventAsync.when(
            data: (event) {
              return messagesAsync.when(
                data: (messages) {
                  final allMessages = [
                    ..._pendingMessages,
                    ...messages,
                  ];
                  return _ChatInput(
                    controller: _messageController,
                    focusNode: _focusNode,
                    onSend: _sendMessage,
                    replyingTo: _replyingTo,
                    onCancelReply: () {
                      setState(() {
                        _replyingTo = null;
                      });
                    },
                    eventStateColor: _getEventStateColor(event.status),
                    eventStatus: event.status,
                    showSuggestions: allMessages.isEmpty,
                    ref: ref,
                    eventId: widget.eventId,
                  );
                },
                loading: () => _ChatInput(
                  controller: _messageController,
                  focusNode: _focusNode,
                  onSend: _sendMessage,
                  replyingTo: _replyingTo,
                  onCancelReply: () {
                    setState(() {
                      _replyingTo = null;
                    });
                  },
                  eventStateColor: _getEventStateColor(event.status),
                  eventStatus: event.status,
                  showSuggestions: false,
                  ref: ref,
                  eventId: widget.eventId,
                ),
                error: (_, __) => _ChatInput(
                  controller: _messageController,
                  focusNode: _focusNode,
                  onSend: _sendMessage,
                  replyingTo: _replyingTo,
                  onCancelReply: () {
                    setState(() {
                      _replyingTo = null;
                    });
                  },
                  eventStateColor: _getEventStateColor(event.status),
                  eventStatus: event.status,
                  showSuggestions: false,
                  ref: ref,
                  eventId: widget.eventId,
                ),
              );
            },
            loading: () => _ChatInput(
              controller: _messageController,
              focusNode: _focusNode,
              onSend: _sendMessage,
              replyingTo: _replyingTo,
              onCancelReply: () {
                setState(() {
                  _replyingTo = null;
                });
              },
              eventStateColor: _getEventStateColor(null),
              eventStatus: null,
              showSuggestions: false,
              ref: ref,
              eventId: widget.eventId,
            ),
            error: (_, __) => _ChatInput(
              controller: _messageController,
              focusNode: _focusNode,
              onSend: _sendMessage,
              replyingTo: _replyingTo,
              onCancelReply: () {
                setState(() {
                  _replyingTo = null;
                });
              },
              eventStateColor: _getEventStateColor(null),
              eventStatus: null,
              showSuggestions: false,
              ref: ref,
              eventId: widget.eventId,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dedicated chat AppBar with overflow-safe dynamic content
/// Handles subtitle, pinned message banner, and notification banner
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBackPressed;
  final bool notificationsMuted;
  final bool showBanner;
  final VoidCallback onToggleNotifications;
  final ChatMessage? pinnedMessage;
  final VoidCallback? onPinnedMessageTap;

  const _ChatAppBar({
    required this.title,
    this.subtitle,
    required this.onBackPressed,
    required this.notificationsMuted,
    required this.showBanner,
    required this.onToggleNotifications,
    this.pinnedMessage,
    this.onPinnedMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: BrandColors.bg1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main AppBar row (back + title + notifications) - NO bottom padding
            Padding(
              padding: const EdgeInsets.only(
                left: Insets.screenH,
                right: Insets.screenH,
                top: 12,
              ),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: onBackPressed,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: BrandColors.text1,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: Gaps.sm),

                    // Title (centered)
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.titleMediumEmph.copyWith(
                          color: BrandColors.text1,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(width: Gaps.sm),

                    // Notification toggle button
                    GestureDetector(
                      onTap: onToggleNotifications,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Icon(
                          notificationsMuted
                              ? Icons.notifications_off
                              : Icons.notifications,
                          color: BrandColors.text1,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subtitle (optional) - 8px from title (Gaps.xs)
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(
                    left: Insets.screenH,
                    right: Insets.screenH,
                    bottom: Gaps.xs),
                child: Text(
                  subtitle!,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

            // Pinned message banner (optional)
            if (pinnedMessage != null)
              GestureDetector(
                onTap: onPinnedMessageTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.screenH,
                    vertical: Gaps.sm,
                  ),
                  color: BrandColors.bg3,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.push_pin,
                        size: IconSizes.sm,
                        color: BrandColors.text2,
                      ),
                      const SizedBox(width: Gaps.sm),
                      Expanded(
                        child: Text(
                          pinnedMessage!.content,
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Notification banner (optional, auto-hides)
            if (showBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.screenH,
                  vertical: Gaps.xs,
                ),
                color: BrandColors.bg2,
                child: Text(
                  notificationsMuted
                      ? 'Chat message notifications muted'
                      : 'Chat message notifications enabled',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    // Calculate dynamic height based on content
    // Base: 12 top padding + 32 row height = 44
    double height = 44;

    if (subtitle != null) {
      // Subtitle: ~20px text height + 8px bottom padding (Gaps.xs) = 28px
      height += 28;
    }

    if (pinnedMessage != null) {
      // Pinned banner: 12px (Gaps.sm) padding * 2 + ~20px content = ~44px
      height += 44;
    }

    if (showBanner) {
      // Notification banner: 4px (Gaps.xs) padding * 2 + ~16px content = ~24px
      height += 24;
    }

    return Size.fromHeight(height);
  }
}

/// Messages list with date separators and unread indicator
/// Chat input widget with dynamic action button
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;
  final Color eventStateColor;
  final EventStatus? eventStatus;
  final bool showSuggestions;
  final WidgetRef ref;
  final String eventId;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.replyingTo,
    this.onCancelReply,
    required this.eventStateColor,
    this.eventStatus,
    this.showSuggestions = false,
    required this.ref,
    required this.eventId,
  });

  Future<void> _showAddExpenseBottomSheet(BuildContext context) async {
    // Get event participants
    final participantsAsync =
        await ref.read(eventParticipantsProvider(eventId).future);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Helper function to display "You" for current user
    String getUserDisplayName(String userId, String userName) {
      return userId == currentUserId ? 'You' : userName;
    }

    final participants = participantsAsync
        .map((p) => ExpenseParticipantOption(
              id: p.userId,
              name: getUserDisplayName(p.userId, p.displayName),
              avatarUrl: p.avatarUrl,
            ))
        .toList();

    if (!context.mounted) return;

    AddExpenseBottomSheet.show(
      context: context,
      participants: participants,
      onAddExpense: (title, paidBy, participantsOwe, amount) async {
        // Create expense using expense provider
        try {
          await ref.read(eventExpensesProvider(eventId).notifier).addExpense(
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
            TopBanner.showError(context, message: 'Failed to add expense: $e');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: Pads.sectionH,
        right: Pads.sectionH,
        bottom: Pads.sectionH,
        top: Pads.ctlVXs,
      ),
      color: BrandColors.bg1,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message suggestions (empty state)
            if (showSuggestions)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.sectionH,
                  ),
                  child: MessageSuggestionsList(
                    onSuggestionTap: (suggestion) {
                      controller.text = suggestion;
                    },
                  ),
                ),
              ),

            // Reply banner
            if (replyingTo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Gaps.sm,
                ),
                margin: const EdgeInsets.only(bottom: Gaps.xs),
                decoration: BoxDecoration(
                  color: BrandColors.bg2,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply,
                      size: IconSizes.sm,
                      color: BrandColors.text2,
                    ),
                    const SizedBox(width: Gaps.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ${replyingTo!.userName}',
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text2,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            replyingTo!.content,
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(
                        Icons.close,
                        size: IconSizes.sm,
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ),
              ),

            // Input field
            Container(
              constraints: const BoxConstraints(
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: BrandColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Camera/Add Photo button (Living/Recap only)
                  // Hidden when text field has text or is focused
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final hasText = value.text.trim().isNotEmpty;
                      final isFocused = focusNode.hasFocus;
                      final shouldHide = hasText || isFocused;

                      if (shouldHide ||
                          (eventStatus != EventStatus.living &&
                              eventStatus != EventStatus.recap)) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(
                          left: Gaps.xxs,
                          bottom: Gaps.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: eventStatus == EventStatus.living
                              ? BrandColors.living
                              : BrandColors.recap,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();

                              // Recap mode: open gallery with multi-select (max 5)
                              if (eventStatus == EventStatus.recap) {
                                final picker = ImagePicker();
                                final selectedImages =
                                    await picker.pickMultiImage(
                                  maxWidth: 1920,
                                  maxHeight: 1920,
                                  imageQuality: 85,
                                );

                                if (selectedImages.isNotEmpty &&
                                    context.mounted) {
                                  // Limit to 5 photos
                                  final limitedImages =
                                      selectedImages.take(5).toList();

                                  if (limitedImages.length <
                                          selectedImages.length &&
                                      context.mounted) {
                                    TopBanner.showInfo(
                                      context,
                                      message: 'Maximum 5 photos selected',
                                    );
                                  }

                                  // Navigate to ManageMemoryPage with selected photos
                                  if (context.mounted) {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.manageMemory,
                                      arguments: {
                                        'memoryId': eventId,
                                        'selectedPhotos': limitedImages
                                            .map((img) => img.path)
                                            .toList(),
                                      },
                                    );
                                  }
                                }
                              } else {
                                // Living mode: TODO - implement camera
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('📸 Camera upload coming soon!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(Radii.pill),
                            child: Icon(
                              eventStatus == EventStatus.living
                                  ? Icons.camera_alt
                                  : Icons.add_photo_alternate,
                              size: IconSizes.smAlt,
                              color: BrandColors.text1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Message input field
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Pads.ctlH,
                          vertical: Pads.ctlV,
                        ),
                      ),
                      maxLines: null,
                      maxLength: 500,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(500),
                      ],
                      buildCounter: (context,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),

                  // Dynamic action button: expense icon when empty, "send" when text exists
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final hasText = value.text.trim().isNotEmpty;

                      return Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(
                          right: Gaps.xxs,
                          bottom: Gaps.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: hasText
                              ? (eventStatus == EventStatus.living
                                  ? BrandColors.living
                                  : eventStatus == EventStatus.recap
                                      ? BrandColors.recap
                                      : BrandColors.planning)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (hasText) {
                                onSend();
                              } else {
                                // Show add expense bottom sheet
                                _showAddExpenseBottomSheet(context);
                              }
                              HapticFeedback.lightImpact();
                            },
                            borderRadius: BorderRadius.circular(Radii.pill),
                            child: Icon(
                              hasText
                                  ? Icons.send
                                  : Icons.receipt_long_outlined,
                              size: IconSizes.smAlt,
                              color: hasText
                                  ? BrandColors.text1
                                  : BrandColors.text2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message action menu (bottom sheet)
