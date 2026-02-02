import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final Function(String groupId)? onAccept;
  final Function(String groupId)? onDecline;
  final Function(String paymentId)? onMarkPaid; // Mark payment as paid

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onActionTap,
    this.onAccept,
    this.onDecline,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShowActionButtons = _shouldShowActionButtons();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: Gaps.md),
                Expanded(child: _buildNotificationTextWithTime()),
              ],
            ),
            // Show action buttons if applicable
            if (shouldShowActionButtons) ...[
              const SizedBox(height: Gaps.md),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowActionButtons() {
    final type = notification.type;

    // Group invite has buttons
    if (type == NotificationType.groupInviteReceived &&
        notification.groupId != null) {
      return true;
    }

    // paymentsAddedYouOwe no longer shows action button (just taps to event)
    // Payment requests still have action buttons

    // Some PUSH notifications have action buttons
    if ([
      NotificationType.uploadsOpen,
      NotificationType.uploadsClosing,
      NotificationType.paymentsRequest,
    ].contains(type)) {
      return true;
    }

    return false;
  }

  Widget _buildActionButtons(BuildContext context) {
    final type = notification.type;

    // Uploads: View Event button
    if (type == NotificationType.uploadsOpen ||
        type == NotificationType.uploadsClosing) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onActionTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.planning,
            foregroundColor: BrandColors.text1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
            elevation: 0,
          ),
          child: Text(
            'View Event',
            style: AppText.labelLarge.copyWith(
              color: BrandColors.text1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Payment Request: View Payments button
    if (type == NotificationType.paymentsRequest) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onActionTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.planning,
            foregroundColor: BrandColors.text1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
            elevation: 0,
          ),
          child: Text(
            'View Payments',
            style: AppText.labelLarge.copyWith(
              color: BrandColors.text1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Group invite: Accept/Decline
    if (type == NotificationType.groupInviteReceived &&
        notification.groupId != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onDecline?.call(notification.groupId!),
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.text2,
                side: const BorderSide(color: BrandColors.bg3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
              ),
              child: Text(
                'Decline',
                style: AppText.labelLarge.copyWith(color: BrandColors.text2),
              ),
            ),
          ),
          const SizedBox(width: Gaps.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onAccept?.call(notification.groupId!),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.planning,
                foregroundColor: BrandColors.text1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
                elevation: 0,
              ),
              child: Text(
                'Accept',
                style: AppText.labelLarge.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // No action button for paymentsAddedYouOwe anymore
    // Just tap on card to navigate to event

    return const SizedBox.shrink();
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
    final timeText = _formatTime(notification.createdAt);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Create a text painter to measure text
        final textPainter = TextPainter(
          text: TextSpan(
            style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            children: parts,
          ),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        // Check if text fits in one line by measuring actual height
        // A single line should be roughly equal to the line height
        final singleLineHeight =
            AppText.bodyMedium.height! * AppText.bodyMedium.fontSize!;
        final fitsInOneLine =
            textPainter.size.height <= singleLineHeight + 2; // 2px tolerance

        if (fitsInOneLine) {
          // If text fits in one line, put time on second line
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                  children: parts,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeText,
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
            ],
          );
        } else {
          // If text takes 2 lines, add time at the end of the text
          final combinedParts = List<TextSpan>.from(parts);
          combinedParts.add(
            TextSpan(
              text: ' $timeText',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          );

          return RichText(
            text: TextSpan(
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              children: combinedParts,
            ),
          );
        }
      },
    );
  }

  List<TextSpan> _parseNotificationText() {
    // Replace placeholders with actual values from notification entity
    String text = notification.formattedMessage;

    // Parse the text to identify bold elements (marked with **)
    return _parseTextWithBoldMarkdown(text);
  }

  List<TextSpan> _parseTextWithBoldMarkdown(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');

    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add normal text before the bold part
      if (match.start > lastEnd) {
        final normalText = text.substring(lastEnd, match.start);
        spans.add(TextSpan(text: normalText));
      }

      // Add bold text with color if it's an amount
      final boldText = match.group(1) ?? '';
      Color? textColor;
      FontWeight fontWeight = FontWeight.w600;

      // Identify if this is an amount (contains € or currency symbol)
      final isAmount = boldText.contains('€') || boldText.contains('\$');

      if (isAmount) {
        // Check notification type to determine color
        if (notification.type == NotificationType.paymentsAddedYouOwe ||
            notification.type == NotificationType.paymentsRequest) {
          textColor = const Color(0xFFFF4444); // Red for debts
        } else if (notification.type == NotificationType.paymentsAddedOwesYou) {
          textColor = const Color(0xFF4CAF50); // Green for receivables
        }
      }

      spans.add(
        TextSpan(
          text: boldText,
          style: AppText.bodyMedium.copyWith(
            color: textColor ?? BrandColors.text1,
            fontWeight: fontWeight,
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining normal text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  String? _getGroupImageUrl() {
    // Em produção, isso viria da entidade de notificação através do groupId
    // Para demo, retorna null para mostrar o ícone placeholder
    // Quando integrado com dados reais, seria algo como:
    // return groupRepository.getGroupById(notification.groupId)?.avatarUrl;
    return null;
  }

  String _getEmojiForNotification() {
    // Se tiver emoji do evento específico, usa esse
    if (notification.eventEmoji != null &&
        notification.eventEmoji!.isNotEmpty) {
      return notification.eventEmoji!;
    }

    // Fallback para emojis genéricos por tipo (só se não tiver emoji específico)
    switch (notification.type) {
      // Legacy types
      case NotificationType.groupInvite:
        return '👥';
      case NotificationType.eventUpdate:
        return '📅';
      case NotificationType.paymentRequest:
        return '💰';
      case NotificationType.general:
        return '📢';

      // PUSH notifications
      case NotificationType.groupInviteReceived:
        return '👥';
      case NotificationType.eventStartsSoon:
      case NotificationType.eventLive:
      case NotificationType.eventEndsSoon:
      case NotificationType.eventExtended:
        return '📅';
      case NotificationType.uploadsOpen:
      case NotificationType.uploadsClosing:
        return '📸';
      case NotificationType.memoryReady:
        return '🎞️';
      case NotificationType.paymentsRequest:
      case NotificationType.paymentsAddedYouOwe:
      case NotificationType.paymentsAddedOwesYou:
      case NotificationType.paymentsPaidYou:
        return '💰';
      case NotificationType.chatMention:
      case NotificationType.chatMessage:
        return '💬';
      case NotificationType.securityNewLogin:
        return '🔐';

      // NOTIFICATIONS (feed)
      case NotificationType.groupInviteAccepted:
      case NotificationType.groupMemberAdded:
      case NotificationType.groupRenamed:
      case NotificationType.groupPhotoChanged:
        return '👥';
      case NotificationType.eventCreated:
      case NotificationType.eventDateSet:
      case NotificationType.eventCanceled:
      case NotificationType.eventRestored:
      case NotificationType.eventConfirmed:
      case NotificationType.eventRsvpReminder:
        return '📅';
      case NotificationType.suggestionAdded:
      case NotificationType.dateSuggestionAdded:
      case NotificationType.locationSuggestionAdded:
        return '💡';
      case NotificationType.rsvpUpdated:
        return '✅';
      case NotificationType.paymentsReceived:
        return '💰';
      case NotificationType.memoryShared:
        return '🎞️';

      // ACTIONS (to-dos)
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
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
