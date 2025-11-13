import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../../../features/event/domain/entities/event_detail.dart';

/// Chip que exibe o status do evento (Pending ou Confirmed)
/// Permite tocar para alternar entre os estados
class EventStatusChip extends StatelessWidget {
  final EventStatus status;
  final VoidCallback onTap;
  final bool isHost; // Shows elevation/shadow if true

  const EventStatusChip({
    super.key,
    required this.status,
    required this.onTap,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == EventStatus.confirmed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          color: isConfirmed ? BrandColors.planning : BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: isConfirmed ? BrandColors.planning : BrandColors.bg3,
            width: 1,
          ),
          // Add shadow for hosts to indicate clickability
          boxShadow: isHost
              ? [
                  BoxShadow(
                    color:
                        (isConfirmed ? BrandColors.planning : BrandColors.bg3)
                            .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          isConfirmed ? 'Confirmed' : 'Pending',
          style: AppText.labelLarge.copyWith(
            color: isConfirmed ? Colors.white : BrandColors.text2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
