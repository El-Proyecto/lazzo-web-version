import 'package:flutter/material.dart';
import '../../../features/event/domain/entities/chat_message.dart';
import '../../../features/event/presentation/widgets/chat_message_bubble.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Reusable chat messages list component
/// Used in both ChatPreviewWidget and EventChatPage
/// Handles chronological ordering, date separators, and "New messages" indicator
class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController? scrollController;
  final Function(ChatMessage)? onMessageLongPress;
  final Function(ChatMessage)? onMessageTap;
  final Function(ChatMessage)? onSwipeReply;
  final Map<String, GlobalKey>? messageKeys;
  final String? currentUserId;
  final Color? bubbleColor;
  final int unreadCount;
  final bool enableSwipeToReply;
  final bool reverse;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const ChatMessagesList({
    super.key,
    required this.messages,
    this.scrollController,
    this.onMessageLongPress,
    this.onMessageTap,
    this.onSwipeReply,
    this.messageKeys,
    this.currentUserId,
    this.bubbleColor,
    this.unreadCount = 0,
    this.enableSwipeToReply = false,
    this.reverse = true,
    this.padding,
    this.physics,
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

  /// Calculate the index where "New messages" separator should appear
  int? _calculateUnreadIndex() {
    if (unreadCount == 0 || currentUserId == null) return null;

    // Count messages from other users until we reach unreadCount
    // Messages are sorted DESC (newest first), so unread messages are at the top
    int otherUserMessageCount = 0;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].userId != currentUserId) {
        otherUserMessageCount++;
        if (otherUserMessageCount == unreadCount) {
          return i;
        }
      }
    }

    return null;
  }

  Color _getBubbleColor(bool isCurrentUser) {
    // Other users ALWAYS get bg3, current user gets event status color
    return isCurrentUser
        ? (bubbleColor ?? BrandColors.planning)
        : BrandColors.bg3;
  }

  @override
  Widget build(BuildContext context) {
    final unreadIndex = _calculateUnreadIndex();
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: Pads.sectionH,
        );
    final effectivePhysics = physics ?? const AlwaysScrollableScrollPhysics();

    return ListView.builder(
      controller: scrollController,
      reverse: reverse,
      physics: effectivePhysics,
      padding: effectivePadding,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.userId == currentUserId;
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

        // Create or get key for this message if messageKeys provided
        GlobalKey? messageKey;
        if (messageKeys != null) {
          messageKeys!.putIfAbsent(message.id, () => GlobalKey());
          messageKey = messageKeys![message.id];
        }

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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Gaps.md),
                child: _UnreadIndicator(
                  color: bubbleColor ?? BrandColors.planning,
                ),
              ),

            // Message bubble with optional GlobalKey for scrolling
            Padding(
              key: messageKey,
              padding: EdgeInsets.only(
                top: isLastInGroup ? Gaps.xs : 2,
                bottom: isLastInGroup ? Gaps.xs : 2,
              ),
              child: ChatMessageBubble(
                message: message,
                isCurrentUser: isCurrentUser,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
                bubbleColor: _getBubbleColor(isCurrentUser),
                onLongPress: onMessageLongPress != null
                    ? () => onMessageLongPress!(message)
                    : null,
                onReplyTap: message.replyTo != null && onMessageTap != null
                    ? () => onMessageTap!(message.replyTo!)
                    : null,
                onSwipeReply: onSwipeReply != null && enableSwipeToReply
                    ? () => onSwipeReply!(message)
                    : null,
                enableSwipeToReply: enableSwipeToReply,
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
  final Color color;

  const _UnreadIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: color,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
          child: Text(
            'New messages',
            style: AppText.bodyMedium.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: color,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
