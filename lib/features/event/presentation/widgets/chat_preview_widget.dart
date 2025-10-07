import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Model for chat message preview in the widget
class ChatMessagePreview {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime timestamp;
  final bool read;

  const ChatMessagePreview({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
    required this.read,
  });
}

/// Chat preview widget showing recent messages and input
class ChatPreviewWidget extends StatefulWidget {
  final int newMessagesCount;
  final String currentUserId;
  final List<ChatMessagePreview> recentMessages;
  final VoidCallback onOpenChat;
  final Function(String content) onSendMessage;

  const ChatPreviewWidget({
    super.key,
    required this.newMessagesCount,
    required this.currentUserId,
    required this.recentMessages,
    required this.onOpenChat,
    required this.onSendMessage,
  });

  @override
  State<ChatPreviewWidget> createState() => _ChatPreviewWidgetState();
}

class _ChatPreviewWidgetState extends State<ChatPreviewWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onSendMessage(content);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort messages by timestamp ascending (oldest first)
    final sortedMessages = [...widget.recentMessages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Get unread messages from other users only
    final unreadMessages = sortedMessages
        .where((m) => !m.read && m.userId != widget.currentUserId)
        .toList();

    // Logic for messages to show:
    // If there are unread messages, show all messages to provide context
    // Otherwise, show last 2 messages as fallback
    final messagesToShow = unreadMessages.isNotEmpty
        ? sortedMessages // Show all messages when there are unread ones
        : (sortedMessages.length >= 2
              ? sortedMessages.sublist(sortedMessages.length - 2)
              : sortedMessages);

    // Calculate height constraints
    final screenHeight = MediaQuery.of(context).size.height;
    final maxChatHeight = screenHeight * 0.4;

    // Estimate height per message (avatar + bubble + spacing + name + timestamp)
    const double messageBubbleHeight = 72.0; // Increased for better spacing
    final double neededHeight = messagesToShow.length * messageBubbleHeight;
    final bool needsScroll = neededHeight > maxChatHeight;
    final double chatHeight = needsScroll ? maxChatHeight : neededHeight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chat', style: AppText.labelLarge),
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
                      color: BrandColors.planning,
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

          // Messages list with dynamic height
          if (messagesToShow.isNotEmpty)
            SizedBox(
              height: chatHeight,
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    physics: needsScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: messagesToShow.length,
                    itemBuilder: (context, index) {
                      final message =
                          messagesToShow[messagesToShow.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.only(top: Gaps.sm),
                        child: _MessageBubble(
                          message: message,
                          isCurrentUser: message.userId == widget.currentUserId,
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
                    color: BrandColors.planning,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _sendMessage();
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual message bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessagePreview message;
  final bool isCurrentUser;

  const _MessageBubble({required this.message, required this.isCurrentUser});

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                radius: 20,
                backgroundColor: BrandColors.bg3,
                backgroundImage: message.userAvatar != null
                    ? NetworkImage(message.userAvatar!)
                    : null,
                child: message.userAvatar == null
                    ? Text(
                        message.userName[0].toUpperCase(),
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
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
                  color: isCurrentUser ? BrandColors.planning : BrandColors.bg3,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text(
                  message.content,
                  style: AppText.bodyMedium.copyWith(
                    color: isCurrentUser ? BrandColors.text1 : BrandColors.text1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Gaps.xxs),
        Padding(
          padding: EdgeInsets.only(left: isCurrentUser ? 0 : 44),
          child: Row(
            mainAxisAlignment: isCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
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
