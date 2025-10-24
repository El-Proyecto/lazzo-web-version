import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
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
  bool _notificationsMuted = false;
  bool _showBanner = false;
  bool _isUserScrolling = false;
  bool _shouldAutoScroll = true;

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
    // If user scrolls up manually, pause auto-scroll
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
    // While typing, enable auto-scroll to bottom
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

    // Auto-hide banner after 3 seconds
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
      ref
          .read(chatMessagesProvider(widget.eventId).notifier)
          .sendMessage(content);
      _messageController.clear();
      _focusNode.requestFocus();

      // Scroll to bottom after sending if auto-scroll is enabled
      if (_shouldAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
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

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            kToolbarHeight +
                (eventAsync.value?.location != null ||
                        eventAsync.value?.startDateTime != null
                    ? 20
                    : 0) +
                (_showBanner ? 40 : 0),
          ),
          child: eventAsync.when(
            data: (event) {
              final subtitle = _formatSubtitle(
                event.startDateTime,
                event.location?.displayName,
              );

              return _ChatAppBar(
                title: event.name,
                subtitle: subtitle.isNotEmpty ? subtitle : null,
                onBackPressed: () => Navigator.of(context).pop(),
                notificationsMuted: _notificationsMuted,
                showBanner: _showBanner,
                onToggleNotifications: _toggleNotifications,
              );
            },
            loading: () => CommonAppBar(
              title: '',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            error: (_, __) => CommonAppBar(
              title: 'Chat',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom app bar for chat with title and subtitle
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBackPressed;
  final bool notificationsMuted;
  final bool showBanner;
  final VoidCallback onToggleNotifications;

  const _ChatAppBar({
    required this.title,
    this.subtitle,
    required this.onBackPressed,
    required this.notificationsMuted,
    required this.showBanner,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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

                // Title (centered, same level as buttons)
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

        // Subtitle (below buttons)
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(
              left: Insets.screenH,
              right: Insets.screenH,
              bottom: Gaps.xs,
            ),
            child: Text(
              subtitle!,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),

        // Notification banner (auto-hides)
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
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize {
    double height = kToolbarHeight;

    // Add space for subtitle if present
    if (subtitle != null) {
      height += 20; // Subtitle height + bottom padding
    }

    // Add space for banner if shown
    if (showBanner) {
      height += 40;
    }

    return Size.fromHeight(height);
  }
}

/// Messages list with date separators and unread indicator
class _MessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const _MessagesList({
    required this.messages,
    required this.scrollController,
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
        horizontal: Insets.screenH,
        vertical: Gaps.md,
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

            // Message bubble
            Padding(
              padding: EdgeInsets.only(
                bottom: isLastInGroup ? Gaps.md : Gaps.xxs,
              ),
              child: _MessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
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
            fontSize: 11,
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
              fontSize: 11,
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

/// Message bubble widget with grouped styling
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isFirstInGroup,
    required this.isLastInGroup,
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
      // Current user: right-aligned
      return BorderRadius.only(
        topLeft: const Radius.circular(Radii.md),
        topRight: Radius.circular(isFirstInGroup ? Radii.md : Radii.sm),
        bottomLeft: const Radius.circular(Radii.md),
        bottomRight: Radius.circular(isLastInGroup ? Radii.md : Radii.sm),
      );
    } else {
      // Other users: left-aligned
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
    // Lower saturation green for user messages
    const userBubbleColor =
        Color(0xFF0D7A2E); // Less saturated than BrandColors.planning

    return Row(
      mainAxisAlignment:
          isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isCurrentUser) ...[
          // Avatar (only on first message in group)
          if (isFirstInGroup)
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

        // Message content
        Flexible(
          child: Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Message bubble
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Gaps.sm,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser ? userBubbleColor : BrandColors.bg3,
                  borderRadius: _getBubbleRadius(),
                ),
                child: Text(
                  message.content,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
              ),

              // Metadata (only on last message in group)
              if (isLastInGroup) ...[
                const SizedBox(height: Gaps.xxs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCurrentUser && isFirstInGroup) ...[
                      Text(
                        message.userName,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: Gaps.xs),
                    ],
                    Text(
                      _formatTimestamp(message.createdAt),
                      style: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Chat input widget with send button
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.screenH,
        vertical: Gaps.md,
      ),
      color: BrandColors.bg1,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Add button (circular green button)
            Container(
              width: TouchTargets.min,
              height: TouchTargets.min,
              decoration: BoxDecoration(
                color: BrandColors.planning,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // TODO: Implement attachment functionality
                    HapticFeedback.lightImpact();
                  },
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: const Icon(
                    Icons.add,
                    color: BrandColors.text1,
                    size: IconSizes.md,
                  ),
                ),
              ),
            ),

            const SizedBox(width: Gaps.sm),

            // Message input field
            Expanded(
              child: Container(
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

                    // Send button (appears when there's text)
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, child) {
                        if (value.text.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.only(
                            right: Gaps.xs,
                            bottom: Gaps.xs,
                          ),
                          decoration: BoxDecoration(
                            color: BrandColors.planning,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                onSend();
                                HapticFeedback.lightImpact();
                              },
                              borderRadius: BorderRadius.circular(Radii.pill),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.send,
                                  size: IconSizes.sm,
                                  color: BrandColors.text1,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
