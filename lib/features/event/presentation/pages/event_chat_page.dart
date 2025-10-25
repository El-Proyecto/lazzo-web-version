import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../providers/event_providers.dart';

/// Event chat page
/// Full-screen chat interface for event communication
class EventChatPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventChatPage({super.key, required this.eventId});

  @override
  ConsumerState<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends ConsumerState<EventChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, GlobalKey> _messageKeys = {};
  bool _notificationsMuted = false;
  bool _showBanner = false;
  bool _isUserScrolling = false;
  bool _shouldAutoScroll = true;
  ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
    }
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_shouldAutoScroll) {
      setState(() {
        _shouldAutoScroll = true;
      });
    }
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsMuted = !_notificationsMuted;
      _showBanner = true;
    });
    HapticFeedback.lightImpact();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      ref.read(chatMessagesProvider(widget.eventId).notifier).sendMessage(
            content,
            replyTo: _replyingTo,
          );
      _messageController.clear();
      setState(() {
        _replyingTo = null;
      });
      // Do NOT request focus after sending - let keyboard stay if user is typing

      if (_shouldAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 0),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void _onMessageLongPress(ChatMessage message) {
    HapticFeedback.mediumImpact();
    _showMessageMenu(message);
  }

  void _showMessageMenu(ChatMessage message) {
    final isCurrentUser = message.userId == 'current-user';

    // Store initial focus state
    final hadFocus = _focusNode.hasFocus;

    // Unfocus before showing modal
    if (hadFocus) {
      FocusScope.of(context).unfocus();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: BrandColors.bg2,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _MessageActionMenu(
        message: message,
        isCurrentUser: isCurrentUser,
        onPin: () => _togglePin(message),
        onReply: () => _replyToMessage(message),
        onDelete: isCurrentUser ? () => _deleteMessage(message) : null,
      ),
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
    Navigator.pop(context);
    FocusScope.of(context).unfocus();

    ref
        .read(chatMessagesProvider(widget.eventId).notifier)
        .togglePin(message.id, !message.isPinned);
    HapticFeedback.lightImpact();
  }

  void _replyToMessage(ChatMessage message) {
    // Close bottom sheet if open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

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
    Navigator.pop(context);
    FocusScope.of(context).unfocus();

    ref
        .read(chatMessagesProvider(widget.eventId).notifier)
        .deleteMessage(message.id);
    HapticFeedback.mediumImpact();
  }

  void _scrollToMessage(ChatMessage message) {
    final messageKey = _messageKeys[message.id];
    if (messageKey?.currentContext != null) {
      // Delay to ensure widget is rendered and list is settled
      Future.delayed(const Duration(milliseconds: 0), () {
        if (!mounted) return;

        final context = messageKey?.currentContext;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 0),
            curve: Curves.easeInOutCubic,
            alignment: 0.5,
          );
          HapticFeedback.lightImpact();
        }
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

    // Use firstWhereOrNull from collection package for nullable result
    final pinnedMessage = messagesAsync.maybeWhen(
      data: (messages) => messages.where((m) => m.isPinned).isNotEmpty
          ? messages.firstWhere((m) => m.isPinned)
          : null,
      orElse: () => null,
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: eventAsync.when(
          data: (event) => _ChatAppBar(
            title: event.name,
            subtitle: _formatSubtitle(
                event.startDateTime, event.location?.displayName),
            onBackPressed: () => Navigator.of(context).pop(),
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
            onBackPressed: () => Navigator.of(context).pop(),
            notificationsMuted: _notificationsMuted,
            showBanner: false,
            onToggleNotifications: () {},
          ),
          error: (_, __) => _ChatAppBar(
            title: 'Chat',
            onBackPressed: () => Navigator.of(context).pop(),
            notificationsMuted: _notificationsMuted,
            showBanner: false,
            onToggleNotifications: () {},
          ),
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet.\nBe the first to start the conversation!',
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Build list with date separators and unread indicator
                  return _MessagesList(
                    messages: messages,
                    scrollController: _scrollController,
                    onMessageLongPress: _onMessageLongPress,
                    onMessageTap: _scrollToMessage,
                    onSwipeReply: _replyToMessage,
                    messageKeys: _messageKeys,
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
              ),
            ),

            // Message input
            _ChatInput(
              controller: _messageController,
              focusNode: _focusNode,
              onSend: _sendMessage,
              replyingTo: _replyingTo,
              onCancelReply: () {
                setState(() {
                  _replyingTo = null;
                });
              },
            ),
          ],
        ),
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
                  bottom: Gaps.xs
                ),
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
    double height = 44; // Base: 12 top padding + 32 row height

    if (subtitle != null) {
      height += 8 + 20; // 8px gap (Gaps.xs) + 14px text height = 20
    }

    if (pinnedMessage != null) {
      height +=
          8 + 37; // 8px gap + banner height (16 padding + 16 content) = 40
    }

    if (showBanner) {
      height += 8 + 28; // 8px gap + banner height (8 padding + 16 content) = 32
    }

    return Size.fromHeight(height);
  }
}

/// Messages list with date separators and unread indicator
class _MessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Function(ChatMessage) onMessageLongPress;
  final Function(ChatMessage) onMessageTap;
  final Function(ChatMessage) onSwipeReply;
  final Map<String, GlobalKey> messageKeys;

  const _MessagesList({
    required this.messages,
    required this.scrollController,
    required this.onMessageLongPress,
    required this.onMessageTap,
    required this.onSwipeReply,
    required this.messageKeys,
  });

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  bool _shouldShowDateSeparator(ChatMessage current, ChatMessage? previous) {
    if (previous == null) return true;

    final currentDate = DateTime(
      current.createdAt.year,
      current.createdAt.month,
      current.createdAt.day,
    );
    final previousDate = DateTime(
      previous.createdAt.year,
      previous.createdAt.month,
      previous.createdAt.day,
    );

    return currentDate != previousDate;
  }

  int? _findUnreadIndex(List<ChatMessage> messages) {
    for (int i = 0; i < messages.length; i++) {
      if (!messages[i].read && messages[i].userId != 'current-user') {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final unreadIndex = _findUnreadIndex(messages);

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.sectionH,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.userId == 'current-user';
        final previousMessage =
            index < messages.length - 1 ? messages[index + 1] : null;
        final nextMessage = index > 0 ? messages[index - 1] : null;

        // Determine if we should show avatar and metadata
        final isFirstInGroup = previousMessage == null ||
            previousMessage.userId != message.userId ||
            message.createdAt.difference(previousMessage.createdAt).inMinutes >
                5;

        final isLastInGroup = nextMessage == null ||
            nextMessage.userId != message.userId ||
            nextMessage.createdAt.difference(message.createdAt).inMinutes > 5;

        final showDateSeparator =
            _shouldShowDateSeparator(message, previousMessage);
        final showUnreadIndicator = unreadIndex != null && index == unreadIndex;

        // Create or get key for this message
        messageKeys.putIfAbsent(message.id, () => GlobalKey());

        return Column(
          children: [
            // Date separator
            if (showDateSeparator)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Gaps.md),
                child: _DateSeparator(
                  label: _formatDateSeparator(message.createdAt),
                ),
              ),

            // Unread indicator
            if (showUnreadIndicator)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Gaps.md),
                child: _UnreadIndicator(),
              ),

            // Message bubble with GlobalKey for scrolling
            Padding(
              key: messageKeys[message.id],
              padding: EdgeInsets.only(
                top: isLastInGroup ? Gaps.xs : 2,
                bottom: isLastInGroup ? Gaps.xs : 2,
              ),
              child: _MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
                onLongPress: () => onMessageLongPress(message),
                onReplyTap: message.replyTo != null
                    ? () => onMessageTap(message.replyTo!)
                    : null,
                onSwipeReply: () => onSwipeReply(message),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Date separator pill
class _DateSeparator extends StatelessWidget {
  final String label;

  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Gaps.sm,
          vertical: Gaps.xxs,
        ),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          label,
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text2,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Unread messages indicator
class _UnreadIndicator extends StatelessWidget {
  const _UnreadIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: BrandColors.planning,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
          child: Text(
            'New messages',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.planning,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: BrandColors.planning,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Message bubble widget with grouped styling and swipe-to-reply
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback onLongPress;
  final VoidCallback? onReplyTap;
  final VoidCallback onSwipeReply;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.onLongPress,
    this.onReplyTap,
    required this.onSwipeReply,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  BorderRadius _getBubbleRadius() {
    if (isCurrentUser) {
      return BorderRadius.only(
        topLeft: const Radius.circular(Radii.md),
        topRight: Radius.circular(isFirstInGroup ? Radii.md : Radii.sm),
        bottomLeft: const Radius.circular(Radii.md),
        bottomRight: Radius.circular(isLastInGroup ? Radii.md : Radii.sm),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(isFirstInGroup ? Radii.md : Radii.sm),
        topRight: const Radius.circular(Radii.md),
        bottomLeft: Radius.circular(isLastInGroup ? Radii.md : Radii.sm),
        bottomRight: const Radius.circular(Radii.md),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const userBubbleColor = Color(0xFF0D7A2E);
    final bubbleColor = message.isDeleted
        ? (isCurrentUser
            ? userBubbleColor.withValues(alpha: 0.3)
            : BrandColors.bg3.withValues(alpha: 0.5))
        : (isCurrentUser ? userBubbleColor : BrandColors.bg3);

    // The actual bubble content (without avatar)
    final bubbleContent = GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Reply preview bubble (if replying to a message)
          if (message.replyTo != null) ...[
            GestureDetector(
              onTap: onReplyTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Gaps.xs,
                ),
                margin: const EdgeInsets.only(bottom: Gaps.xxs),
                decoration: BoxDecoration(
                  color: (isCurrentUser ? userBubbleColor : BrandColors.bg3)
                      .withValues(alpha: 0.3),
                  borderRadius: _getBubbleRadius(),
                ),
                child: Text(
                  message.replyTo!.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],

          // Main message bubble
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Pads.ctlH,
              vertical: Gaps.sm,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: _getBubbleRadius(),
            ),
            child: Text(
              message.content,
              style: AppText.bodyMedium.copyWith(
                color: message.isDeleted
                    ? BrandColors.text2.withValues(alpha: 0.6)
                    : BrandColors.text1,
                fontStyle:
                    message.isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),

          // Metadata (only on last message in group)
          if (isLastInGroup) ...[
            const SizedBox(height: Gaps.xxs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCurrentUser) ...[
                  Text(
                    message.userName,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: Gaps.xs),
                ],
                Text(
                  _formatTimestamp(message.createdAt),
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // Wrap ONLY the bubble content with Dismissible
    final swipeableBubble = Dismissible(
      key: ValueKey('${message.id}-swipe'),
      direction: isCurrentUser
          ? DismissDirection.endToStart
          : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onSwipeReply();
        return false;
      },
      background: Container(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        padding: EdgeInsets.only(
          left: isCurrentUser ? 0 : Pads.sectionH,
          right: isCurrentUser ? Pads.sectionH : 0,
        ),
        child: const Icon(
          Icons.reply,
          color: BrandColors.text2,
          size: IconSizes.md,
        ),
      ),
      child: bubbleContent,
    );

    // Final Row with avatar + swipeable bubble
    return Row(
      mainAxisAlignment:
          isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isCurrentUser) ...[
          // Avatar only on LAST message in group (bottom-most)
          if (isLastInGroup)
            CircleAvatar(
              radius: 16,
              backgroundColor: BrandColors.bg3,
              backgroundImage: message.userAvatar != null
                  ? NetworkImage(message.userAvatar!)
                  : null,
              child: message.userAvatar == null
                  ? Text(
                      message.userName[0].toUpperCase(),
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            )
          else
            const SizedBox(width: 32),
          const SizedBox(width: Gaps.xs),
        ],
        Flexible(child: swipeableBubble),
      ],
    );
  }
}

/// Chat input widget with dynamic action button
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.replyingTo,
    this.onCancelReply,
  });

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
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),

                  // Dynamic action button: "+" when empty, "send" when text exists
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
                          color: BrandColors.planning,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (hasText) {
                                onSend();
                              } else {
                                Navigator.pushNamed(
                                    context, AppRouter.createEvent);
                              }
                              HapticFeedback.lightImpact();
                            },
                            borderRadius: BorderRadius.circular(Radii.pill),
                            child: Icon(
                              hasText ? Icons.send : Icons.add,
                              size: hasText ? IconSizes.sm : IconSizes.smAlt,
                              color: BrandColors.text1,
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
class _MessageActionMenu extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback onPin;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _MessageActionMenu({
    required this.message,
    required this.isCurrentUser,
    required this.onPin,
    required this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Pads.sectionV),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin/Unpin option
            _MenuOption(
              icon: message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              label: message.isPinned ? 'Unpin' : 'Pin',
              onTap: onPin,
            ),

            // Reply option
            _MenuOption(
              icon: Icons.reply,
              label: 'Reply',
              onTap: onReply,
            ),

            // Delete option (only for current user)
            if (onDelete != null) ...[
              const Divider(color: BrandColors.border, height: 1),
              _MenuOption(
                icon: Icons.delete_outline,
                label: 'Eliminar',
                onTap: onDelete!,
                isDestructive: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Individual menu option
class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.bg2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.sectionH,
            vertical: Pads.ctlV,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: IconSizes.sm,
                color: isDestructive ? BrandColors.cantVote : BrandColors.text1,
              ),
              const SizedBox(width: Gaps.md),
              Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  color:
                      isDestructive ? BrandColors.cantVote : BrandColors.text1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
