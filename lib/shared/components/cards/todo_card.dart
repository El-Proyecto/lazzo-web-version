import 'package:flutter/material.dart';
import '../../../features/home/domain/entities/todo_entity.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Compact to-do card for home page
/// Shows action name, event emoji/name, and time left
class TodoCard extends StatelessWidget {
  final TodoEntity todo;
  final VoidCallback? onTap;

  const TodoCard({
    super.key,
    required this.todo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.sectionH),
        decoration: BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            // Event emoji (compact - 32px)
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  todo.eventEmoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: Gaps.sm),

            // Action + Event + Group column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action name
                  Text(
                    todo.actionName,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Gaps.xs / 2),

                  // Event name with icon
                  Row(
                    children: [
                      const Icon(
                        Icons.event,
                        color: BrandColors.text2,
                        size: IconSizes.sm,
                      ),
                      const SizedBox(width: Gaps.xs / 2),
                      Flexible(
                        child: Text(
                          todo.eventName,
                          style: AppText.bodyMedium.copyWith(
                            color: BrandColors.text2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gaps.sm),

            // Time left indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: _getTimeLeftColor(),
                  size: IconSizes.sm,
                ),
                const SizedBox(width: Gaps.xs / 2),
                Text(
                  todo.deadlineText ?? 'No deadline',
                  style: AppText.labelLarge.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTimeLeftColor() {
    if (todo.isOverdue) {
      return BrandColors.cantVote; // Red
    }

    final timeLeft = todo.timeLeft;
    if (timeLeft == null) return BrandColors.text2;

    if (timeLeft.inHours <= 2) {
      return BrandColors.cantVote; // Red - urgent
    } else if (timeLeft.inHours <= 24) {
      return BrandColors.recap; // Orange - warning
    } else {
      return BrandColors.planning; // Green - good
    }
  }
}
