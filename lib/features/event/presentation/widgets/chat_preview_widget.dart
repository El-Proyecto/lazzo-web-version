import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Chat preview widget for event page
/// Shows last 2 messages and input field
class ChatPreviewWidget extends StatefulWidget {
  final List<ChatMessagePreview> recentMessages;
  final VoidCallback onOpenChat;
  final Function(String message) onSendMessage;

  const ChatPreviewWidget({
    super.key,
    required this.recentMessages,
    required this.onOpenChat,
    required this.onSendMessage,
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
          InkWell(
            onTap: widget.onOpenChat,
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chat', style: AppText.labelLarge),
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
          if (widget.recentMessages.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Gaps.lg),
                child: Text(
                  'Nenhuma mensagem ainda',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              ),
            ),
          ] else ...[
            ...widget.recentMessages.map(
              (msg) => Padding(
                padding: const EdgeInsets.only(bottom: Gaps.sm),
                child: _MessageBubble(
                  userName: msg.userName,
                  content: msg.content,
                  timestamp: msg.timestamp,
                ),
              ),
            ),
          ],
          const SizedBox(height: Gaps.sm),

          // Input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: AppText.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Escrever mensagem...',
                    hintStyle: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                    filled: true,
                    fillColor: BrandColors.bg3,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Pads.ctlH,
                      vertical: Pads.ctlV,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gaps.xs),
              Container(
                width: TouchTargets.min,
                height: TouchTargets.min,
                decoration: BoxDecoration(
                  color: BrandColors.planning,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onSendMessage(_controller.text.trim());
                      _controller.clear();
                    }
                  },
                  icon: const Icon(
                    Icons.send,
                    size: IconSizes.sm,
                    color: BrandColors.text1,
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

/// Chat message preview data model
class ChatMessagePreview {
  final String userName;
  final String content;
  final DateTime timestamp;

  const ChatMessagePreview({
    required this.userName,
    required this.content,
    required this.timestamp,
  });
}

/// Internal message bubble widget
class _MessageBubble extends StatelessWidget {
  final String userName;
  final String content;
  final DateTime timestamp;

  const _MessageBubble({
    required this.userName,
    required this.content,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(userName, style: AppText.bodyMediumEmph),
            const SizedBox(width: Gaps.xs),
            Text(
              _formatTime(timestamp),
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gaps.xxs),
        Text(content, style: AppText.bodyMedium),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'agora';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}
