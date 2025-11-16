import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

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
                icon: message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
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
    print('\n📤 [ChatPreviewWidget] _sendMessage called');
    print('   - Content: "$content"');
    print('   - isEmpty: ${content.isEmpty}');
    print('   - Replying to: ${_replyingTo?.content}');
    if (content.isNotEmpty && widget.onSendMessage != null) {
      print('   - Calling widget.onSendMessage with replyTo...');
      widget.onSendMessage!(content, replyTo: _replyingTo);
      _controller.clear();
      setState(() {
        _replyingTo = null;
      });
      print('   ✅ Message sent, controller cleared, reply context cleared');
    } else if (widget.onSendMessage == null) {
      print('   ⚠️ onSendMessage is null, cannot send');
    } else {
      print('   ⚠️ Content is empty, not sending');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('\n🔄 [ChatPreviewWidget] Building with ${widget.recentMessages.length} messages');
    print('   - New messages count: ${widget.newMessagesCount}');
    
    // Sort messages by timestamp ASCENDING (oldest first)
    final sortedMessages = [...widget.recentMessages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    print('📊 [ChatPreviewWidget] All sorted (oldest first):');
    for (var i = 0; i < sortedMessages.length && i < 3; i++) {
      print('   $i: "${sortedMessages[i].content}" at ${sortedMessages[i].timestamp}');
    }
    if (sortedMessages.length > 3) {
      print('   ... (${sortedMessages.length - 3} more)');
      for (var i = sortedMessages.length - 3; i < sortedMessages.length; i++) {
        print('   $i: "${sortedMessages[i].content}" at ${sortedMessages[i].timestamp}');
      }
    }

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
    
    print('✅ [ChatPreviewWidget] Showing ${messagesToShow.length} messages:');
    for (var i = 0; i < messagesToShow.length; i++) {
      print('   $i: "${messagesToShow[i].content}" (${messagesToShow[i].userName}) at ${messagesToShow[i].timestamp}');
    }

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
            final messageId = '${pinnedMsg.userId}_${pinnedMsg.timestamp.millisecondsSinceEpoch}';
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
                    physics: needsScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: messagesToShow.length,
                    itemBuilder: (context, index) {
                      // reverse=true means: index 0 = bottom (newest), last index = top (oldest)
                      // We want to show messagesToShow in natural order (oldest to newest)
                      // So we reverse the array access
                      final reversedIndex = messagesToShow.length - 1 - index;
                      final message = messagesToShow[reversedIndex];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == 0 ? 0 : Gaps.md,
                        ),
                        child: GestureDetector(
                          onLongPress: () => _showMessageActions(message),
                          child: _MessageBubble(
                            message: message,
                            isCurrentUser: message.userId == widget.currentUserId,
                            onReplyTap: message.replyTo != null
                                ? () {
                                    // Navigate to chat and scroll to replied message
                                    if (widget.onOpenChatWithMessage != null) {
                                      final replyMessageId = '${message.replyTo!.userId}_${message.replyTo!.timestamp.millisecondsSinceEpoch}';
                                      widget.onOpenChatWithMessage!(replyMessageId);
                                    } else if (widget.onOpenChat != null) {
                                      widget.onOpenChat!();
                                    }
                                  }
                                : null,
                          ),
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
                      onTap: widget.onSendMessage != null ? () {
                        _sendMessage();
                        HapticFeedback.lightImpact();
                      } : null,
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

/// Individual message bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessagePreview message;
  final bool isCurrentUser;
  final VoidCallback? onReplyTap;
  final ChatMode mode;

  const _MessageBubble({
    
    required this.message,
   
    required this.isCurrentUser,
    this.onReplyTap,
  ,
    required this.mode,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final isToday = now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;

    if (isToday) {
      // Show time in HH:mm format for messages today
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
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
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser ? BrandColors.planning : BrandColors.bg3;
    
    // Debug: Check if message has replyTo
    if (message.replyTo != null) {
      print('🔄 [_MessageBubble] Rendering reply indicator for "${message.content.substring(0, message.content.length > 15 ? 15 : message.content.length)}..." replying to "${message.replyTo!.content.substring(0, message.replyTo!.content.length > 15 ? 15 : message.replyTo!.content.length)}..."');
    }
    
    return Column(
      crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Reply preview bubble (if replying to a message)
        if (message.replyTo != null) ...[
          Padding(
            padding: EdgeInsets.only(
              left: isCurrentUser ? 0 : 40,
              right: isCurrentUser ? 0 : 0,
              bottom: Gaps.xxs,
            ),
            child: GestureDetector(
              onTap: onReplyTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Gaps.xs,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: const Border(
                    left: BorderSide(
                      color: BrandColors.text2,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.reply,
                      size: 14,
                      color: BrandColors.text2,
                    ),
                    const SizedBox(width: Gaps.xs),
                    Flexible(
                      child: Text(
                        message.replyTo!.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar only shown for other users (not current user)
            if (!isCurrentUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: BrandColors.bg3,
                foregroundImage: message.userAvatar != null && message.userAvatar!.isNotEmpty
                    ? NetworkImage(message.userAvatar!)
                    : null,
                onForegroundImageError: (exception, stackTrace) {
                  // Log error but don't crash
                  debugPrint('❌ Failed to load avatar: ${message.userAvatar}');
                  debugPrint('   Error: $exception');
                },
                child: Text(
                  message.userName.isNotEmpty 
                      ? message.userName[0].toUpperCase()
                      : '?',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: Gaps.xs),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Gaps.sm,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? (mode == ChatMode.living
                          ? BrandColors.living
                          : BrandColors.planning)
                      : BrandColors.bg3,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text(
                  message.content,
                  style: AppText.bodyMedium.copyWith(
                    color:
                        isCurrentUser ? BrandColors.text1 : BrandColors.text1,
                  ),
                ),
              ),
            ),
            // No avatar for current user messages - keeps it clean like WhatsApp
          ],
        ),
        const SizedBox(height: Gaps.xxs),
        // Name and timestamp below bubble (only timestamp for current user)
        Padding(
          padding: EdgeInsets.only(
            left: isCurrentUser ? 0 : 40,
            right: isCurrentUser ? 0 : 0,
          ),
          child: Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Show name only for other users, not for current user
              if (!isCurrentUser) ...[
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
                _formatTimestamp(message.timestamp),
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
                  color: isDestructive ? BrandColors.cantVote : BrandColors.text1,
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
