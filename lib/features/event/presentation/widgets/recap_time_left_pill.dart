import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Pill showing time remaining for a recap event (orange accent)
/// Displays countdown until recap phase ends (24h after event end)
class RecapTimeLeftPill extends StatelessWidget {
  final DateTime recapEndTime;

  const RecapTimeLeftPill({
    super.key,
    required this.recapEndTime,
  });

  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return 'Ending soon';
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}m left';
      }
      return '${hours}h left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m left';
    } else {
      return 'Ending soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLeft = recapEndTime.difference(now);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Pads.ctlH,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        color: BrandColors.recap,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTimeLeft(timeLeft),
            style: AppText.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
