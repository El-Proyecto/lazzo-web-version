import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Gaps.md),
        decoration: ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: Gaps.md),
            Expanded(child: _buildNotificationTextWithTime()),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Se for convite para grupo, mostra foto do grupo
    if (notification.type == NotificationType.groupInvite) {
      return _buildGroupPhoto();
    }

    // Caso contrário, mostra emoji do evento
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Text(
          _getEmojiForNotification(),
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildGroupPhoto() {
    return Container(
      width: 40,
      height: 40,
      decoration: ShapeDecoration(
        color: BrandColors.bg3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        // Em produção, isso viria da entidade de notificação
        // Para demo, usando um placeholder
        image: _getGroupImageUrl() != null
            ? DecorationImage(
                image: NetworkImage(_getGroupImageUrl()!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _getGroupImageUrl() == null
          ? const Icon(Icons.group, color: BrandColors.text2, size: 20)
          : null,
    );
  }

  Widget _buildNotificationTextWithTime() {
    // Parse the notification description to identify important parts
    final parts = _parseNotificationText();

    // Add the time at the end
    parts.add(
      TextSpan(
        text: ' ${_formatTime(notification.createdAt)}',
        style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
      ),
    );

    return RichText(
      text: TextSpan(
        style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
        children: parts,
      ),
    );
  }

  List<TextSpan> _parseNotificationText() {
    final description = notification.description;

    // Different parsing based on notification type
    switch (notification.type) {
      case NotificationType.paymentRequest:
        // Example: "Ana requested €25.50 for restaurant bill"
        // Make name and amount bold, amount red if it's owed
        return _parsePaymentNotification(description);
      case NotificationType.groupInvite:
        // Example: "João invited you to join "Summer Trip Planning""
        return _parseGroupInviteNotification(description);
      case NotificationType.eventUpdate:
        // Example: "Beach BBQ location has been changed"
        return _parseEventUpdateNotification(description);
      default:
        return [TextSpan(text: description)];
    }
  }

  List<TextSpan> _parsePaymentNotification(String text) {
    // Simple parsing for demo - in real implementation, you'd have structured data
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\w+)\s+(requested|owes you|you owe)\s+(€[\d.,]+)');
    final match = regex.firstMatch(text);

    if (match != null) {
      final name = match.group(1)!;
      final action = match.group(2)!;
      final amount = match.group(3)!;

      spans.add(
        TextSpan(
          text: name,
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      spans.add(TextSpan(text: ' $action '));
      spans.add(
        TextSpan(
          text: amount,
          style: AppText.bodyMedium.copyWith(
            color: action.contains('owe')
                ? BrandColors.cantVote
                : BrandColors.planning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      // Add remaining text if any
      final remainingText = text.substring(match.end);
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(text: remainingText));
      }
    } else {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  List<TextSpan> _parseGroupInviteNotification(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\w+)\s+invited you to join\s+"([^"]+)"');
    final match = regex.firstMatch(text);

    if (match != null) {
      final name = match.group(1)!;
      final groupName = match.group(2)!;

      spans.add(
        TextSpan(
          text: name,
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      spans.add(TextSpan(text: ' invited you to join '));
      spans.add(
        TextSpan(
          text: '"$groupName"',
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  List<TextSpan> _parseEventUpdateNotification(String text) {
    final spans = <TextSpan>[];
    // Handle both quoted and unquoted event names
    // Example: "Beach BBQ location has been changed"
    final quotedRegex = RegExp(r'"([^"]+)"\s+(.+)');
    final match = quotedRegex.firstMatch(text);

    if (match != null) {
      final eventName = match.group(1)!;
      final action = match.group(2)!;

      spans.add(
        TextSpan(
          text: '"$eventName"',
          style: AppText.bodyMedium.copyWith(
            color: BrandColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      spans.add(TextSpan(text: ' $action.'));
    } else {
      // Try without quotes
      final parts = text.split(' ');
      if (parts.length >= 2) {
        spans.add(
          TextSpan(
            text: parts[0] + ' ' + parts[1],
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text1,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        spans.add(TextSpan(text: ' ${parts.skip(2).join(' ')}.'));
      } else {
        spans.add(TextSpan(text: text));
      }
    }

    return spans;
  }

  String? _getGroupImageUrl() {
    // Em produção, isso viria da entidade de notificação através do groupId
    // Para demo, retorna null para mostrar o ícone placeholder
    // Quando integrado com dados reais, seria algo como:
    // return groupRepository.getGroupById(notification.groupId)?.avatarUrl;
    return null;
  }

  String _getEmojiForNotification() {
    switch (notification.type) {
      case NotificationType.groupInvite:
        return '👥'; // Group emoji
      case NotificationType.eventUpdate:
        return '📅'; // Event emoji
      case NotificationType.paymentRequest:
        return '💰'; // Money emoji
      case NotificationType.general:
        return '📢'; // General notification emoji
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
