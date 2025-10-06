import 'package:flutter/material.dart';
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
              Row(
                children: [
                  Text('Chat', style: AppText.labelLarge),
                  if (widget.newMessagesCount > 0) ...[
                    const SizedBox(width: Gaps.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gaps.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.planning,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Text(
                        widget.newMessagesCount.toString(),
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.bg1,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: widget.onOpenChat,
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gaps.xs,
                    vertical: Gaps.xxs,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Open chat',
                        style: AppText.bodyMedium.copyWith(
                          color: BrandColors.text2,
                        ),
                      ),
                      const SizedBox(width: Gaps.xxs),
                      const Icon(
                        Icons.chevron_right,
                        size: IconSizes.sm,
                        color: BrandColors.text2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: Gaps.md),

          // Recent messages (showing oldest to newest for proper order)
          if (sortedMessages.isNotEmpty) ...[
            ...sortedMessages.map(
              (message) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.sm),
                child: _MessageBubble(
                  message: message,
                  isCurrentUser: message.userId == widget.currentUserId,
                ),
              ),
            ),
            const SizedBox(height: Gaps.md),
          ],

          // Message input
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: BrandColors.bg3,
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(color: BrandColors.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Pads.ctlH,
                        vertical: Pads.ctlV,
                      ),
                    ),
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: Gaps.sm),
              InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(Radii.pill),
                child: Container(
                  width: TouchTargets.min,
                  height: TouchTargets.min,
                  decoration: BoxDecoration(
                    color: BrandColors.planning,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: BrandColors.bg1,
                    size: IconSizes.sm,
                  ),
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isCurrentUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCurrentUser) ...[
          // Avatar for other users
          CircleAvatar(
            radius: 14,
            backgroundColor: BrandColors.bg3,
            backgroundImage: message.userAvatar != null
                ? NetworkImage(message.userAvatar!)
                : null,
            child: message.userAvatar == null
                ? Text(
                    message.userName[0].toUpperCase(),
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 12,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser) ...[
                  Text(
                    message.userName,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message.content,
                  style: AppText.bodyMedium.copyWith(
                    color: isCurrentUser ? BrandColors.bg1 : BrandColors.text1,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isCurrentUser) ...[
          const SizedBox(width: Gaps.xs),
          // Avatar for current user
          CircleAvatar(
            radius: 14,
            backgroundColor: BrandColors.planning.withOpacity(0.2),
            child: Text(
              message.userName[0].toUpperCase(),
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.planning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
