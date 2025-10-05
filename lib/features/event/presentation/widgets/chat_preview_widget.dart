import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Chat preview widget for event page
/// Shows recent messages and rounded input
class ChatPreviewWidget extends StatefulWidget {
  final List<ChatMessagePreview> recentMessages;
  final int newMessagesCount;
  final VoidCallback onOpenChat;
  final Function(String message) onSendMessage;
  final String? currentUserId;

  const ChatPreviewWidget({
    super.key,
    required this.recentMessages,
    required this.newMessagesCount,
    required this.onOpenChat,
    required this.onSendMessage,
    this.currentUserId,
  });

  @override
  State<ChatPreviewWidget> createState() => _ChatPreviewWidgetState();
}

class _ChatPreviewWidgetState extends State<ChatPreviewWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show only 2-3 most recent messages
    final displayMessages = widget.recentMessages.take(3).toList();
    
    return Container(
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
          InkWell(
            onTap: widget.onOpenChat,
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chat', style: AppText.labelLarge),
                      if (widget.newMessagesCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${widget.newMessagesCount} new message${widget.newMessagesCount > 1 ? 's' : ''}',
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: IconSizes.sm,
                    color: BrandColors.text2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gaps.md),

          // Recent messages
          if (displayMessages.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Gaps.lg),
                child: Text(
                  'No messages yet',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              ),
            ),
          ] else ...[
            ...displayMessages.map(
              (msg) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.md),
                child: _MessageBubble(
                  userName: msg.userName,
                  userAvatar: msg.userAvatar,
                  content: msg.content,
                  timestamp: msg.timestamp,
                  isCurrentUser: msg.userId == widget.currentUserId,
                ),
              ),
            ),
          ],
          const SizedBox(height: Gaps.sm),

          // Fully rounded input field with send button inside
          Container(
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppText.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: AppText.bodyMedium.copyWith(
                        color: BrandColors.text2,
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Pads.ctlH,
                        vertical: Pads.ctlV,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Send button inside the rounded box
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: BrandColors.planning,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty) {
                          widget.onSendMessage(_controller.text.trim());
                          _controller.clear();
                        }
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.send,
                        size: 18,
                        color: BrandColors.text1,
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

/// Chat message preview data model
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

/// Internal message bubble widget - only shows avatar for other users
class _MessageBubble extends StatelessWidget {
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime timestamp;
  final bool isCurrentUser;

  const _MessageBubble({
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar on the left ONLY for other users
        if (!isCurrentUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: BrandColors.bg3,
            child: userAvatar != null
                ? ClipOval(
                    child: Image.network(
                      userAvatar!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: Gaps.xs),
        ],

        // Message bubble
        Flexible(
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Pads.ctlV,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser ? BrandColors.planning.withValues(alpha: 0.15) : BrandColors.bg3,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isCurrentUser ? Radii.md : Radii.smAlt),
                    topRight: Radius.circular(isCurrentUser ? Radii.smAlt : Radii.md),
                    bottomLeft: const Radius.circular(Radii.md),
                    bottomRight: const Radius.circular(Radii.md),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gaps.xxs),
                        child: Text(
                          userName,
                          style: AppText.bodyMediumEmph.copyWith(fontSize: 12),
                        ),
                      ),
                    Text(content, style: AppText.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: Gaps.xxs),
              // Timestamp below bubble
              Text(
                _formatTime(timestamp),
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

  Widget _buildDefaultAvatar() {
    return Text(
      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
      style: AppText.bodyMediumEmph.copyWith(
        color: BrandColors.text2,
        fontSize: 14,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
