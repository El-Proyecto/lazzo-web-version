import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/chat_message.dart';

/// Reusable chat message bubble component
/// Used in both EventChatPage (full chat) and ChatPreviewWidget (preview)
class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final Color bubbleColor;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyTap;
  final VoidCallback? onSwipeReply;
  final bool enableSwipeToReply;
  final String Function(DateTime)? formatTimestamp;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    required this.bubbleColor,
    this.onLongPress,
    this.onReplyTap,
    this.onSwipeReply,
    this.enableSwipeToReply = false,
    this.formatTimestamp,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  double _dragDistance = 0;
  double _startDragX = 0;

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  BorderRadius _getBubbleRadius() {
    if (widget.isCurrentUser) {
      return BorderRadius.only(
        topLeft: const Radius.circular(Radii.md),
        topRight: Radius.circular(widget.isFirstInGroup ? Radii.md : Radii.sm),
        bottomLeft: const Radius.circular(Radii.md),
        bottomRight:
            Radius.circular(widget.isLastInGroup ? Radii.md : Radii.sm),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(widget.isFirstInGroup ? Radii.md : Radii.sm),
        topRight: const Radius.circular(Radii.md),
        bottomLeft: Radius.circular(widget.isLastInGroup ? Radii.md : Radii.sm),
        bottomRight: const Radius.circular(Radii.md),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.message.isDeleted
        ? (widget.isCurrentUser
            ? widget.bubbleColor.withValues(alpha: 0.3)
            : BrandColors.bg3.withValues(alpha: 0.5))
        : widget.bubbleColor;

    // Only the bubble content (without metadata)
    final messageBubble = GestureDetector(
      onLongPress: widget.onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Reply preview bubble (if replying to a message)
          if (widget.message.replyTo != null) ...[
            GestureDetector(
              onTap: widget.onReplyTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Pads.ctlH,
                  vertical: Gaps.xs,
                ),
                margin: const EdgeInsets.only(bottom: Gaps.xxs),
                decoration: BoxDecoration(
                  color: (widget.isCurrentUser
                          ? widget.bubbleColor
                          : BrandColors.bg3)
                      .withValues(alpha: 0.3),
                  borderRadius: _getBubbleRadius(),
                ),
                child: Text(
                  widget.message.replyTo!.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],

          // Main message bubble
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Pads.ctlH,
              vertical: Gaps.sm,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: _getBubbleRadius(),
            ),
            child: widget.message.isDeleted
                ? Text(
                    'Message Deleted',
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(
                    widget.message.content,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
          ),
        ],
      ),
    );

    // Wrap bubble with swipe gesture and transform
    final swipeableBubble =
        widget.enableSwipeToReply && widget.onSwipeReply != null
            ? RawGestureDetector(
                gestures: {
                  HorizontalDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          HorizontalDragGestureRecognizer>(
                    () => HorizontalDragGestureRecognizer(debugOwner: this),
                    (HorizontalDragGestureRecognizer instance) {
                      instance
                        ..onStart = (details) {
                          setState(() {
                            _startDragX = details.localPosition.dx;
                            _dragDistance = 0;
                          });
                        }
                        ..onUpdate = (details) {
                          setState(() {
                            _dragDistance =
                                details.localPosition.dx - _startDragX;
                          });
                        }
                        ..onEnd = (details) {
                          // Current user messages: detect LEFT swipe (negative distance)
                          // Other user messages: detect RIGHT swipe (positive distance)
                          final threshold = 34.0; // pixels
                          final isValidSwipe = widget.isCurrentUser
                              ? _dragDistance < -threshold // Swipe left
                              : _dragDistance > threshold; // Swipe right

                          if (isValidSwipe) {
                            widget.onSwipeReply!();
                            HapticFeedback.lightImpact();
                          }

                          setState(() {
                            _dragDistance = 0;
                            _startDragX = 0;
                          });
                        }
                        ..onCancel = () {
                          setState(() {
                            _dragDistance = 0;
                            _startDragX = 0;
                          });
                        };
                    },
                  ),
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: widget.isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  children: [
                    // Transform to move bubble during swipe
                    Transform.translate(
                      offset: Offset(
                        widget.isCurrentUser
                            ? _dragDistance.clamp(-34.0, 0.0)
                            : _dragDistance.clamp(0.0, 34.0),
                        0,
                      ),
                      child: messageBubble,
                    ),
                    // Reply icon animation - appears as bubble moves away
                    if (_dragDistance.abs() > 5)
                      Positioned(
                        right: widget.isCurrentUser ? 0 : null,
                        left: widget.isCurrentUser ? null : 0,
                        child: _ReplySwipeIndicator(
                          progress: (_dragDistance.abs() / 34).clamp(0.0, 1.0),
                        ),
                      ),
                  ],
                ),
              )
            : messageBubble;

    // Complete bubble content with metadata
    final bubbleContent = Column(
      crossAxisAlignment: widget.isCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        swipeableBubble,
        // Metadata (only on last message in group) - stays fixed during swipe
        if (widget.isLastInGroup) ...[
          const SizedBox(height: Gaps.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isCurrentUser) ...[
                Text(
                  widget.message.userName,
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: Gaps.xs),
              ],
              Text(
                widget.formatTimestamp != null
                    ? widget.formatTimestamp!(widget.message.createdAt)
                    : _formatTimestamp(widget.message.createdAt),
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontSize: 12,
                ),
              ),
              // Status indicator for current user messages
              if (widget.isCurrentUser) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.message.isPending
                      ? Icons.access_time
                      : (widget.message.isReadBySomeone
                          ? Icons.done_all
                          : Icons.done),
                  size: 14,
                  color: widget.message.isPending
                      ? BrandColors.text2.withValues(alpha: 0.5)
                      : (widget.message.isReadBySomeone
                          ? BrandColors.planning
                          : BrandColors.text2),
                ),
              ],
            ],
          ),
        ],
      ],
    );

    // Final Row with avatar + bubble content
    return Row(
      mainAxisAlignment: widget.isCurrentUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!widget.isCurrentUser) ...[
          // Avatar only on LAST message in group (bottom-most)
          if (widget.isLastInGroup)
            CircleAvatar(
              radius: 16,
              backgroundColor: BrandColors.bg3,
              backgroundImage: widget.message.userAvatar != null
                  ? NetworkImage(widget.message.userAvatar!)
                  : null,
              child: widget.message.userAvatar == null
                  ? Text(
                      widget.message.userName[0].toUpperCase(),
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
        Flexible(child: bubbleContent),
      ],
    );
  }
}

/// Reply swipe indicator (simple icon, no circular progress)
class _ReplySwipeIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const _ReplySwipeIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: progress.clamp(0.3, 1.0),
      duration: const Duration(milliseconds: 50),
      child: Icon(
        Icons.reply,
        size: IconSizes.md,
        color: progress >= 1.0 ? BrandColors.planning : BrandColors.text2,
      ),
    );
  }
}
