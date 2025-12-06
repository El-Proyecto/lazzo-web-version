import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Bottom sheet for message actions (pin, reply, delete)
/// Used in event chat and chat preview
class MessageActionsSheet extends StatelessWidget {
  final DateTime messageTimestamp;
  final bool isPinned;
  final bool showDelete;
  final VoidCallback onPin;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const MessageActionsSheet({
    super.key,
    required this.messageTimestamp,
    required this.isPinned,
    required this.showDelete,
    required this.onPin,
    required this.onReply,
    this.onDelete,
  });

  /// Show message actions bottom sheet
  static Future<void> show({
    required BuildContext context,
    required DateTime messageTimestamp,
    required bool isPinned,
    required bool showDelete,
    required VoidCallback onPin,
    required VoidCallback onReply,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => MessageActionsSheet(
        messageTimestamp: messageTimestamp,
        isPinned: isPinned,
        showDelete: showDelete,
        onPin: onPin,
        onReply: onReply,
        onDelete: onDelete,
      ),
    );
  }

  String _formatMessageTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      messageTimestamp.year,
      messageTimestamp.month,
      messageTimestamp.day,
    );

    String dayLabel;
    if (messageDate == today) {
      dayLabel = 'Today';
    } else if (messageDate == yesterday) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel = DateFormat('d MMM').format(messageTimestamp);
    }

    final timeLabel = DateFormat('HH:mm').format(messageTimestamp);
    return 'Sent $dayLabel at $timeLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with timestamp
            Padding(
              padding: const EdgeInsets.only(
                left: Pads.sectionH,
                right: Pads.sectionH,
                top: Pads.sectionV,
                bottom: Gaps.md,
              ),
              child: Text(
                _formatMessageTime(),
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Actions list (no separators between options)
            _ActionOption(
              icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              label: isPinned ? 'Unpin message' : 'Pin message',
              onTap: () {
                Navigator.of(context).pop();
                onPin();
              },
            ),

            _ActionOption(
              icon: Icons.reply,
              label: 'Reply',
              onTap: () {
                Navigator.of(context).pop();
                onReply();
              },
            ),

            if (showDelete && onDelete != null)
              _ActionOption(
                icon: Icons.delete_outline,
                label: 'Delete message',
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
              ),

            const SizedBox(height: Pads.sectionV),
          ],
        ),
      ),
    );
  }
}

/// Individual action option button
class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.bg2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Pads.sectionH,
            vertical: Pads.ctlV,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: IconSizes.sm,
                color: isDestructive ? BrandColors.cantVote : BrandColors.text1,
              ),
              const SizedBox(width: Gaps.md),
              Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  color:
                      isDestructive ? BrandColors.cantVote : BrandColors.text1,
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
