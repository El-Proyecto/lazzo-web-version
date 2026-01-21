import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/dialogs/message_actions_sheet.dart';
import '../../../../shared/components/widgets/chat_messages_list.dart';
import '../../../../shared/components/widgets/message_suggestions.dart';
import '../../domain/entities/chat_message.dart';

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
  final bool isReadBySomeone;
  final bool isPinned;
  final bool isDeleted;
  final bool isPending;
  final ChatMessagePreview? replyTo;

  const ChatMessagePreview({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
    required this.isReadBySomeone,
    this.isPinned = false,
    this.isDeleted = false,
    this.isPending = false,
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

  // Optimistic UI: pending messages waiting to be confirmed
  final List<ChatMessagePreview> _pendingMessages = [];

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

    MessageActionsSheet.show(
      context: context,
      messageTimestamp: message.timestamp,
      isPinned: message.isPinned,
      showDelete: isCurrentUser,
      onPin: () {
        if (widget.onPinMessage != null) {
          widget.onPinMessage!(message);
        }
      },
      onReply: () {
        if (widget.onReplyMessage != null) {
          setState(() {
            _replyingTo = message;
            _focusNode.requestFocus();
          });
        }
      },
      onDelete: isCurrentUser && widget.onDeleteMessage != null
          ? () => widget.onDeleteMessage!(message)
          : null,
    );
  }

  void _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isNotEmpty && widget.onSendMessage != null) {
      // Create optimistic pending message
      final pendingMessage = ChatMessagePreview(
        userId: widget.currentUserId,
        userName: 'You',
        content: content,
        timestamp: DateTime.now(),
        isReadBySomeone: false,
        isPending: true,
        replyTo: _replyingTo,
      );

      setState(() {
        _pendingMessages.add(pendingMessage);
      });

      // Send to parent (will trigger server call)
      widget.onSendMessage!(content, replyTo: _replyingTo);

      _controller.clear();
      setState(() {
        _replyingTo = null;
      });

      // Pending message will be automatically removed when real message arrives
      // (filtered in the build method when matching content is found in widget.recentMessages)
    } else if (widget.onSendMessage == null) {
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    // Filter out pending messages that already exist in real messages
    // Match by content, userId, and approximate timestamp (within 5 seconds)
    final filteredPendingMessages = _pendingMessages.where((pending) {
      final hasDuplicate = widget.recentMessages.any((real) =>
          real.content == pending.content &&
          real.userId == pending.userId &&
          real.timestamp.difference(pending.timestamp).abs().inSeconds < 5);

      if (hasDuplicate) {
        // Remove from pending list in next frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _pendingMessages.removeWhere((p) =>
                  p.content == pending.content && p.userId == pending.userId);
            });
          }
        });
      }

      return !hasDuplicate;
    }).toList();

    // Combine filtered pending messages with real messages
    final allMessages = [...filteredPendingMessages, ...widget.recentMessages];

    // Sort messages by timestamp DESCENDING (newest first for easier slicing)
    final sortedMessages = [...allMessages]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // ALWAYS show last 10 messages (most recent)
    // This ensures preview shows the latest conversation context
    // Keep them in DESCENDING order (newest first) because ChatMessagesList
    // with reverse:true will display them correctly (newest at top)
    List<ChatMessagePreview> messagesToShow = sortedMessages.length <= 10
        ? sortedMessages
        : sortedMessages.take(10).toList();

    // Calculate height constraints
    final screenHeight = MediaQuery.of(context).size.height;
    final maxChatHeight = screenHeight * 0.4;

    // Estimate height per message (avatar + bubble + spacing + name + timestamp)
    const double messageBubbleHeight = 72.0;
    final double neededHeight =
        messagesToShow.length * messageBubbleHeight + 8.0; // +8 for padding
    final double minChatHeight = 160.0 > neededHeight ? 160.0 : neededHeight;
    final bool needsScroll = neededHeight > maxChatHeight;
    final double chatHeight = needsScroll ? maxChatHeight : minChatHeight;
    return Hero(
      tag: 'chat-widget',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: BrandColors.bg1,
            border: Border.all(color: BrandColors.bg2, width: 4),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with bg2 background
              Container(
                padding: const EdgeInsets.all(Pads.sectionH - 2),
                decoration: const BoxDecoration(
                  color: BrandColors.bg2,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Radii.md - 4),
                    topRight: Radius.circular(Radii.md - 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: widget.onOpenChat,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gaps.xxs,
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
              ),

              // Pinned messages section (full width, same style as event_chat_page)
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
                      horizontal: Insets.screenH,
                      vertical: Gaps.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      color: BrandColors.bg3,
                    ),
                    margin: const EdgeInsets.only(
                        top: Gaps.xs, left: Pads.ctlV, right: Pads.ctlV),
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

              // Content area with bg1 background
              Padding(
                padding: const EdgeInsets.only(
                    left: Pads.sectionH,
                    right: Pads.sectionH,
                    bottom: Pads.sectionH),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Messages list with dynamic height using shared component
                    if (messagesToShow.isNotEmpty)
                      Container(
                        height: chatHeight,
                        padding: const EdgeInsets.only(top: 0, bottom: 0),
                        child: Stack(
                          children: [
                            ChatMessagesList(
                              messages: messagesToShow
                                  .map((preview) =>
                                      _adaptPreviewToMessage(preview))
                                  .toList(),
                              currentUserId: widget.currentUserId,
                              unreadCount: widget.newMessagesCount,
                              bubbleColor: widget.mode == ChatMode.living
                                  ? BrandColors.living
                                  : BrandColors.planning,
                              reverse: true,
                              padding: EdgeInsets.zero,
                              physics: const AlwaysScrollableScrollPhysics(),
                              enableSwipeToReply: true,
                              onSwipeReply: (message) {
                                // Find original preview to set as replying
                                final preview = messagesToShow.firstWhere(
                                  (p) =>
                                      p.userId == message.userId &&
                                      p.timestamp == message.createdAt,
                                  orElse: () => ChatMessagePreview(
                                    userId: message.userId,
                                    userName: message.userName,
                                    content: message.content,
                                    timestamp: message.createdAt,
                                    isReadBySomeone: false,
                                  ),
                                );
                                setState(() {
                                  _replyingTo = preview;
                                  _focusNode.requestFocus();
                                });
                              },
                              onMessageLongPress: (message) {
                                // Find original preview to pass to action handler
                                final preview = messagesToShow.firstWhere(
                                  (p) =>
                                      p.userId == message.userId &&
                                      p.timestamp == message.createdAt,
                                  orElse: () => ChatMessagePreview(
                                    userId: message.userId,
                                    userName: message.userName,
                                    content: message.content,
                                    timestamp: message.createdAt,
                                    isReadBySomeone: false,
                                  ),
                                );
                                _showMessageActions(preview);
                              },
                              onMessageTap: (message) {
                                // Navigate to chat and scroll to replied message
                                if (widget.onOpenChatWithMessage != null) {
                                  final replyMessageId =
                                      '${message.userId}_${message.createdAt.millisecondsSinceEpoch}';
                                  widget.onOpenChatWithMessage!(replyMessageId);
                                } else if (widget.onOpenChat != null) {
                                  widget.onOpenChat!();
                                }
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
                                        BrandColors.bg1,
                                        BrandColors.bg1.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: Gaps.xs),

                    // Message suggestions (empty state)
                    if (messagesToShow.isEmpty)
                      MessageSuggestionsList(
                        onSuggestionTap: (suggestion) {
                          _controller.text = suggestion;
                        },
                      ),

                    // Reply indicator (when replying to a message - same style as event_chat_page)
                    if (_replyingTo != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: Gaps.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Pads.ctlH,
                          vertical: Gaps.sm,
                        ),
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
                                    'Replying to ${_replyingTo!.userName}',
                                    style: AppText.bodyMedium.copyWith(
                                      color: BrandColors.text2,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _replyingTo!.content,
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
                              onTap: () {
                                setState(() {
                                  _replyingTo = null;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: IconSizes.sm,
                                color: BrandColors.text2,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Message input
                    Container(
                      margin: const EdgeInsets.only(top: Gaps.xs),
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
    isPinned: preview.isPinned,
    isDeleted: preview.isDeleted,
    isPending: preview.isPending,
    isReadBySomeone: preview.isReadBySomeone,
    replyTo: preview.replyTo != null
        ? ChatMessage(
            id: '${preview.replyTo!.userId}_${preview.replyTo!.timestamp.millisecondsSinceEpoch}',
            eventId: '',
            userId: preview.replyTo!.userId,
            userName: preview.replyTo!.userName,
            userAvatar: preview.replyTo!.userAvatar,
            content: preview.replyTo!.content,
            createdAt: preview.replyTo!.timestamp,
            isReadBySomeone: preview.replyTo!.isReadBySomeone,
          )
        : null,
  );
}

/// Action button for message actions bottom sheet
