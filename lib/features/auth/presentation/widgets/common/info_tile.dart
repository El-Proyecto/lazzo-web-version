// lib/features/profile/presentation/widgets/common/info_tile.dart
import 'package:flutter/material.dart';

enum RequiredMark { none, before, after }

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.background,
    required this.label,
    required this.value,
    this.requiredMark = RequiredMark.none,
    this.onTap,
  });

  final Color background;
  final String label;
  final String value;
  final RequiredMark requiredMark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: const TextStyle(
        color: Color(0xFFF2F2F2),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.10,
      ),
    );

    const star = Text(
      '*',
      style: TextStyle(
        color: Color(0xFFFF3B30),
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.40,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 370,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadows: const [
            BoxShadow(
              color: Color(0x3F282828),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (requiredMark == RequiredMark.before) star,
                if (requiredMark == RequiredMark.before) const SizedBox(width: 8),
                labelText,
                if (requiredMark == RequiredMark.after) const SizedBox(width: 8),
                if (requiredMark == RequiredMark.after) star,
              ],
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA5A5A5),
                      fontSize: 14,
                      height: 1.43,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Transform.rotate(
                  angle: -1.5708,
                  child: const Icon(Icons.chevron_left, size: 20, color: Color(0xFFA5A5A5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
