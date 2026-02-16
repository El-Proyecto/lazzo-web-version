import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/rsvp.dart';

/// A list tile displaying a guest's avatar, name, vote time, and RSVP status.
/// Used in the ManageGuests page guest list.
class GuestListTile extends StatelessWidget {
  final Rsvp rsvp;
  final VoidCallback? onTap;

  const GuestListTile({
    super.key,
    required this.rsvp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Pads.ctlVXs,
          horizontal: Pads.sectionH,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: BrandColors.bg3,
              child: rsvp.userAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        rsvp.userAvatar!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                      ),
                    )
                  : _buildDefaultAvatar(),
            ),
            const SizedBox(width: Gaps.sm),

            // Name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rsvp.userName,
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(rsvp.createdAt),
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),

            // RSVP status label
            Text(
              _statusLabel(rsvp.status),
              style: AppText.titleMediumEmph.copyWith(
                color: _statusColor(rsvp.status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      rsvp.userName.isNotEmpty ? rsvp.userName[0].toUpperCase() : '?',
      style: AppText.bodyMediumEmph.copyWith(
        color: BrandColors.text2,
        fontSize: 18,
      ),
    );
  }

  static String _statusLabel(RsvpStatus status) {
    switch (status) {
      case RsvpStatus.going:
        return 'Can';
      case RsvpStatus.maybe:
        return 'Maybe';
      case RsvpStatus.notGoing:
        return "Can't";
      case RsvpStatus.pending:
        return 'Pending';
    }
  }

  static Color _statusColor(RsvpStatus status) {
    switch (status) {
      case RsvpStatus.going:
        return BrandColors.planning;
      case RsvpStatus.maybe:
        return BrandColors.warning;
      case RsvpStatus.notGoing:
        return BrandColors.cantVote;
      case RsvpStatus.pending:
        return BrandColors.text2;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
