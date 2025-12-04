import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_message_bubble.dart';

/// Mode for chat preview widget
enum ChatMode {
  planning,
  living,
}

/// Model for chat message preview in the widget
class ChatMessagePreview {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime timestamp;
  final bool read;
  final bool isPinned;
  final ChatMessagePreview? replyTo;

  const ChatMessagePreview({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
    required this.read,
    this.isPinned = false,
    this.replyTo,
  });
}

/// Chat preview widget showing recent messages and input
class ChatPreviewWidget extends StatefulWidget {
  final int newMessagesCount;
  final String currentUserId;
  final List<ChatMessagePreview> recentMessages;
  final VoidCallback? onOpenChat;
  final Function(String messageId)? onOpenChatWithMessage;
  final Function(String content, {ChatMessagePreview? replyTo})? onSendMessage;
  final Function(ChatMessagePreview message)? onPinMessage;
  final Function(ChatMessagePreview message)? onDeleteMessage;
  final Function(ChatMessagePreview message)? onReplyMessage;
  final ChatMode mode;

  const ChatPreviewWidget({
    super.key,
    required this.newMessagesCount,
    required this.currentUserId,
    required this.recentMessages,
    this.onOpenChat,
    this.onOpenChatWithMessage,
    this.onSendMessage,
    this.onPinMessage,
    this.onDeleteMessage,
    this.onReplyMessage,
    this.mode = ChatMode.planning,
  });

  @override
  State<ChatPreviewWidget> createState() => _ChatPreviewWidgetState();
}

class _ChatPreviewWidgetState extends State<ChatPreviewWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ChatMessagePreview? _replyingTo;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showMessageActions(ChatMessagePreview message) {
    final isCurrentUser = message.userId == widget.currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: BrandColors.bg2,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.screenH,
          vertical: Gaps.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pin/Unpin
            if (widget.onPinMessage != null)
              _ActionButton(
                icon:
                    message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: message.isPinned ? 'Unpin message' : 'Pin message',
                onTap: () {
                  Navigator.pop(context);
                  widget.onPinMessage!(message);
                },
              ),

            // Reply
            if (widget.onReplyMessage != null)
              _ActionButton(
                icon: Icons.reply,
                label: 'Reply',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingTo = message;
                    _focusNode.requestFocus();
                  });
                },
              ),

            // Delete (only for current user)
            if (isCurrentUser && widget.onDeleteMessage != null)
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Delete message',
                onTap: () {
                  Navigator.pop(context);
                  widget.onDeleteMessage!(message);
                },
                isDestructive: true,
              ),

            const SizedBox(height: Gaps.sm),

            // Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: BrandColors.bg3,
                padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isNotEmpty && widget.onSendMessage != null) {
      widget.onSendMessage!(content, replyTo: _replyingTo);
      _controller.clear();
      setState(() {
        _replyingTo = null;
      });
    } else if (widget.onSendMessage == null) {
      print('   ⚠️ onSendMessage is null, cannot send');
    } else {
      print('   ⚠️ Content is empty, not sending');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort messages by timestamp ASCENDING (oldest first)
    final sortedMessages = [...widget.recentMessages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Get unread messages from other users (keep chronological order)
    final unreadMessages = sortedMessages
        .where((m) => !m.read && m.userId != widget.currentUserId)
        .toList();

    // Show unread messages OR last 3 messages (most recent context)
    final messagesToShow = unreadMessages.isNotEmpty
        ? unreadMessages
        : (sortedMessages.length <= 3
            ? sortedMessages
            : sortedMessages.skip(sortedMessages.length - 3).toList());

    // Calculate height constraints
    final screenHeight = MediaQuery.of(context).size.height;
    final maxChatHeight = screenHeight * 0.4;

    // Estimate height per message (avatar + bubble + spacing + name + timestamp)
    const double messageBubbleHeight = 72.0;
    final double neededHeight = messagesToShow.length * messageBubbleHeight;
    final bool needsScroll = neededHeight > maxChatHeight;
    final double chatHeight = needsScroll ? maxChatHeight : neededHeight;
    return Hero(
      tag: 'chat-widget',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Pads.sectionH),
          decoration: BoxDecoration(
            color: BrandColors.bg2,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: widget.onOpenChat,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gaps.xs,
                        vertical: Gaps.xxs,
                      ),
                      child: Text('Chat', style: AppText.labelLarge),
                    ),
                  ),
                  if (widget.newMessagesCount > 0)
                    InkWell(
                      onTap: widget.onOpenChat,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gaps.sm,
                          vertical: Gaps.xs,
                        ),
                        decoration: BoxDecoration(
                          color: widget.mode == ChatMode.living
                              ? BrandColors.living
                              : BrandColors.planning,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          '${widget.newMessagesCount} new',
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text1,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: Gaps.xxs),

              // Pinned messages section (same style as chat_page)
              ...sortedMessages.where((m) => m.isPinned).map((pinnedMsg) {
                // Generate messageId similar to event_chat_page (userId + timestamp)
                final messageId =
                    '${pinnedMsg.userId}_${pinnedMsg.timestamp.millisecondsSinceEpoch}';
                return GestureDetector(
                  onTap: () {
                    if (widget.onOpenChatWithMessage != null) {
                      widget.onOpenChatWithMessage!(messageId);
                    } else if (widget.onOpenChat != null) {
                      widget.onOpenChat!();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Pads.ctlH,
                      vertical: Gaps.sm,
                    ),
                    margin: const EdgeInsets.only(bottom: Gaps.xs),
                    decoration: BoxDecoration(
                      color: BrandColors.bg3,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
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
                            pinnedMsg.content,
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
                );
              }),

              // Messages list with dynamic height
              if (messagesToShow.isNotEmpty)
                Container(
                  height: chatHeight,
                  padding: const EdgeInsets.only(top: Gaps.xs, bottom: Gaps.xs),
                  child: Stack(
                    children: [
                      ListView.builder(
                        reverse: true, // Scroll starts at bottom (most recent)
                        padding: EdgeInsets.zero,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Always allow scroll even with few messages
                        itemCount: messagesToShow.length,
                        itemBuilder: (context, index) {
                          // reverse=true means: index 0 = bottom (newest), last index = top (oldest)
                          // We want to show messagesToShow in natural order (oldest to newest)
                          // So we reverse the array access
                          final reversedIndex =
                              messagesToShow.length - 1 - index;
                          final message = messagesToShow[reversedIndex];
                          final isCurrentUser =
                              message.userId == widget.currentUserId;

                          // Get previous and next messages for grouping logic
                          final previousMessage =
                              index < messagesToShow.length - 1
                                  ? messagesToShow[
                                      messagesToShow.length - 1 - (index + 1)]
                                  : null;
                          final nextMessage = index > 0
                              ? messagesToShow[
                                  messagesToShow.length - 1 - (index - 1)]
                              : null;

                          // Determine if we should show avatar and metadata
                          // Same logic as event_chat_page.dart
                          final isFirstInGroup = previousMessage == null ||
                              previousMessage.userId != message.userId ||
                              message.timestamp
                                      .difference(previousMessage.timestamp)
                                      .inMinutes >
                                  5;

                          final isLastInGroup = nextMessage == null ||
                              nextMessage.userId != message.userId ||
                              nextMessage.timestamp
                                      .difference(message.timestamp)
                                      .inMinutes >
                                  5;

                          return Padding(
                            padding: EdgeInsets.only(
                              top: isLastInGroup ? Gaps.xs : 2,
                              bottom: isLastInGroup ? Gaps.xs : 2,
                            ),
                            child: ChatMessageBubble(
                              message: _adaptPreviewToMessage(message),
                              isCurrentUser: isCurrentUser,
                              isFirstInGroup: isFirstInGroup,
                              isLastInGroup: isLastInGroup,
                              bubbleColor: isCurrentUser
                                  ? (widget.mode == ChatMode.living
                                      ? BrandColors.living
                                      : BrandColors.planning)
                                  : BrandColors.bg3,
                              onLongPress: () => _showMessageActions(message),
                              onReplyTap: message.replyTo != null
                                  ? () {
                                      // Navigate to chat and scroll to replied message
                                      if (widget.onOpenChatWithMessage !=
                                          null) {
                                        final replyMessageId =
                                            '${message.replyTo!.userId}_${message.replyTo!.timestamp.millisecondsSinceEpoch}';
                                        widget.onOpenChatWithMessage!(
                                            replyMessageId);
                                      } else if (widget.onOpenChat != null) {
                                        widget.onOpenChat!();
                                      }
                                    }
                                  : null,
                              formatTimestamp: (timestamp) {
                                final now = DateTime.now();
                                final isToday = now.year == timestamp.year &&
                                    now.month == timestamp.month &&
                                    now.day == timestamp.day;

                                if (isToday) {
                                  // Show time in HH:mm format for messages today
                                  final hour =
                                      timestamp.hour.toString().padLeft(2, '0');
                                  final minute = timestamp.minute
                                      .toString()
                                      .padLeft(2, '0');
                                  return '$hour:$minute';
                                } else {
                                  // Show date for older messages
                                  final diff = now.difference(timestamp);
                                  if (diff.inDays == 1) {
                                    return 'Yesterday';
                                  } else if (diff.inDays < 7) {
                                    return '${diff.inDays}d ago';
                                  } else {
                                    return '${timestamp.day}/${timestamp.month}';
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                      // Fade-out gradient at the top when scrollable
                      if (needsScroll)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  BrandColors.bg2,
                                  BrandColors.bg2.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: Gaps.md),

              // Reply indicator (when replying to a message - same style as chat_page)
              if (_replyingTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: Gaps.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Pads.ctlH,
                    vertical: Gaps.sm,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColors.bg3,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 36,
                        decoration: BoxDecoration(
                          color: BrandColors.text2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: Gaps.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _replyingTo!.userName,
                              style: AppText.bodyMedium.copyWith(
                                color: BrandColors.text2,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _replyingTo!.content,
                              style: AppText.bodyMedium.copyWith(
                                color: BrandColors.text1,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: IconSizes.sm,
                          color: BrandColors.text2,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _replyingTo = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),

              // Message input
              Container(
                decoration: BoxDecoration(
                  color: BrandColors.bg3,
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: BrandColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: AppText.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
                          hintStyle: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: Pads.ctlH,
                            vertical: Pads.ctlV,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: Gaps.xs),
                      decoration: BoxDecoration(
                        color: widget.mode == ChatMode.living
                            ? BrandColors.living
                            : BrandColors.planning,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onSendMessage != null
                              ? () {
                                  _sendMessage();
                                  HapticFeedback.lightImpact();
                                }
                              : null,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adapter to convert ChatMessagePreview to ChatMessage for use with ChatMessageBubble
ChatMessage _adaptPreviewToMessage(ChatMessagePreview preview) {
  return ChatMessage(
    id: '${preview.userId}_${preview.timestamp.millisecondsSinceEpoch}',
    eventId: '', // Not needed for display
    userId: preview.userId,
    userName: preview.userName,
    userAvatar: preview.userAvatar,
    content: preview.content,
    createdAt: preview.timestamp,
    isPinned: false,
    isDeleted: false,
    replyTo: preview.replyTo != null
        ? ChatMessage(
            id: '${preview.replyTo!.userId}_${preview.replyTo!.timestamp.millisecondsSinceEpoch}',
            eventId: '',
            userId: preview.replyTo!.userId,
            userName: preview.replyTo!.userName,
            userAvatar: preview.replyTo!.userAvatar,
            content: preview.replyTo!.content,
            createdAt: preview.replyTo!.timestamp,
          )
        : null,
  );
}

/// Action button for message actions bottom sheet
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.ctlH,
            vertical: Pads.ctlV + 4,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: BrandColors.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? BrandColors.cantVote : BrandColors.text1,
                size: IconSizes.md,
              ),
              const SizedBox(width: Gaps.md),
              Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  color:
                      isDestructive ? BrandColors.cantVote : BrandColors.text1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
