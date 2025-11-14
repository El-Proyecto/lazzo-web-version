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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    print('\n📤 [ChatPreviewWidget] _sendMessage called');
    print('   - Content: "$content"');
    print('   - isEmpty: ${content.isEmpty}');
    if (content.isNotEmpty) {
      print('   - Calling widget.onSendMessage...');
      widget.onSendMessage(content);
      _controller.clear();
      print('   ✅ Message sent, controller cleared');
    } else {
      print('   ⚠️ Content is empty, not sending');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('\n🔄 [ChatPreviewWidget] Building with ${widget.recentMessages.length} messages');
    print('   - New messages count: ${widget.newMessagesCount}');
    
    // Sort messages by timestamp DESCENDING (newest first)
    final sortedMessages = [...widget.recentMessages]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print('📊 [ChatPreviewWidget] After sorting (newest first):');
    for (var i = 0; i < sortedMessages.length && i < 5; i++) {
      print('   $i: "${sortedMessages[i].content}" at ${sortedMessages[i].timestamp}');
    }

    // Get unread messages from other users
    final unreadMessages = sortedMessages
        .where((m) => !m.read && m.userId != widget.currentUserId)
        .toList();

    // Show unread messages OR last 3 messages (newest)
    final messagesToShow = unreadMessages.isNotEmpty
        ? unreadMessages
        : sortedMessages.take(3).toList();
    
    print('✅ [ChatPreviewWidget] Showing ${messagesToShow.length} messages:');
    for (var i = 0; i < messagesToShow.length; i++) {
      print('   $i: "${messagesToShow[i].content}" (${messagesToShow[i].userName})');
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
            Container(
              height: chatHeight,
              padding: const EdgeInsets.only(top: Gaps.xs, bottom: Gaps.xs),
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.zero,
                    physics: needsScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: messagesToShow.length,
                    itemBuilder: (context, index) {
                      final message =
                          messagesToShow[messagesToShow.length - 1 - index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == 0 ? 0 : Gaps.md,
                        ),
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
        ),
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
    return Column(
      crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
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
                  color:
                      isCurrentUser ? BrandColors.planning : BrandColors.bg3,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text(
                  message.content,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text1,
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
