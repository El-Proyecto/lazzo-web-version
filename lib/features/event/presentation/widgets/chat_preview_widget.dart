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

  const ChatMessagePreview({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
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
    // Sort messages by timestamp ascending (oldest first) for proper display order
    final sortedMessages = [...widget.recentMessages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
              // Badge with unread count
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
                        color: BrandColors.bg1,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: Gaps.md),

          // Recent messages with scrolling (max 2 visible)
          if (sortedMessages.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 120, // Approximate height for 2 messages
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: sortedMessages.length,
                itemBuilder: (context, index) {
                  final message = sortedMessages[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < sortedMessages.length - 1 ? Gaps.sm : 0,
                    ),
                    child: _MessageBubble(
                      message: message,
                      isCurrentUser: message.userId == widget.currentUserId,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Gaps.md),
          ],

          // Message input (English text, fully rounded corners, send button inside)
          Container(
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(
                Radii.pill,
              ), // Fully rounded corners
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
                      hintText: 'Type a message...', // English text
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
                // Send button inside the input bar
                Container(
                  margin: const EdgeInsets.only(right: Gaps.xs),
                  decoration: BoxDecoration(
                    color: BrandColors.planning,
                    borderRadius: BorderRadius.circular(
                      Radii.pill,
                    ), // Fully rounded send button
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _sendMessage();
                        // Add a subtle haptic feedback
                        HapticFeedback.lightImpact();
                      },
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.send,
                          size: IconSizes.sm,
                          color: BrandColors.bg1,
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
        // Message bubble with avatar
        Row(
          mainAxisAlignment: isCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              // Avatar for other users (made bigger as requested)
              CircleAvatar(
                radius: 20, // Increased to 20 for bigger profile photos
                backgroundColor: BrandColors.bg3,
                backgroundImage: message.userAvatar != null
                    ? NetworkImage(message.userAvatar!)
                    : null,
                child: message.userAvatar == null
                    ? Text(
                        message.userName[0].toUpperCase(),
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                          fontSize: 16, // Increased font size proportionally
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: Gaps.xs),
            ],

            // Message content
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
                    color: isCurrentUser ? BrandColors.bg1 : BrandColors.text1,
                  ),
                ),
              ),
            ),

            // Remove avatar for current user as requested
          ],
        ),

        // Name and timestamp below the bubble (only show name for other users)
        const SizedBox(height: Gaps.xxs),
        Padding(
          padding: EdgeInsets.only(
            left: isCurrentUser
                ? 0
                : 44, // Account for bigger avatar width + spacing
            right: isCurrentUser ? 0 : 0,
          ),
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
