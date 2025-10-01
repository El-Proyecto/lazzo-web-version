import 'package:flutter/material.dart';
import '../../domain/entities/payment_entity.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class PaymentCard extends StatelessWidget {
  final PaymentEntity payment;
  final bool isOwedToUser;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsPaid;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.isOwedToUser,
    this.onTap,
    this.onMarkAsPaid,
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
            side: BorderSide(color: _getBorderColor(), width: 1),
          ),
        ),
        child: Row(
          children: [
            _buildAmountSection(),
            const SizedBox(width: Gaps.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.title,
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  const SizedBox(height: Gaps.xs),
                  Text(
                    payment.description,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                  const SizedBox(height: Gaps.xs),
                  Row(
                    children: [
                      Text(
                        isOwedToUser ? 'Owes you' : 'You owe',
                        style: AppText.labelLarge.copyWith(
                          color: _getStatusColor(),
                        ),
                      ),
                      if (payment.dueDate != null) ...[
                        Text(
                          ' • ',
                          style: AppText.labelLarge.copyWith(
                            color: BrandColors.text2,
                          ),
                        ),
                        Text(
                          _formatDueDate(),
                          style: AppText.labelLarge.copyWith(
                            color: _getDueDateColor(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (payment.status != PaymentStatus.paid &&
                onMarkAsPaid != null) ...[
              const SizedBox(width: Gaps.md),
              _buildActionButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.md,
        vertical: Gaps.sm,
      ),
      decoration: ShapeDecoration(
        color: _getAmountBackgroundColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      child: Column(
        children: [
          Text(
            '€${payment.amount.toStringAsFixed(2)}',
            style: AppText.titleMediumEmph.copyWith(color: Colors.white),
          ),
          if (payment.currency != 'EUR')
            Text(
              payment.currency,
              style: AppText.labelLarge.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: onMarkAsPaid,
      child: Container(
        width: 44,
        height: 44,
        decoration: ShapeDecoration(
          color: BrandColors.planning,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: IconSizes.md),
      ),
    );
  }

  Color _getBorderColor() {
    if (payment.status == PaymentStatus.overdue) {
      return BrandColors.cantVote;
    } else if (payment.status == PaymentStatus.paid) {
      return BrandColors.planning;
    }
    return BrandColors.border;
  }

  Color _getAmountBackgroundColor() {
    if (isOwedToUser) {
      return BrandColors.planning;
    } else {
      return payment.status == PaymentStatus.overdue
          ? BrandColors.cantVote
          : BrandColors.recap;
    }
  }

  Color _getStatusColor() {
    if (isOwedToUser) {
      return BrandColors.planning;
    } else {
      return payment.status == PaymentStatus.overdue
          ? BrandColors.cantVote
          : BrandColors.recap;
    }
  }

  Color _getDueDateColor() {
    if (payment.status == PaymentStatus.overdue) {
      return BrandColors.cantVote;
    }

    if (payment.dueDate != null) {
      final daysLeft = payment.dueDate!.difference(DateTime.now()).inDays;
      if (daysLeft <= 1) {
        return BrandColors.recap;
      }
    }

    return BrandColors.text2;
  }

  String _formatDueDate() {
    if (payment.dueDate == null) return '';

    final now = DateTime.now();
    final dueDate = payment.dueDate!;
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      final overdue = now.difference(dueDate);
      if (overdue.inDays > 0) {
        return '${overdue.inDays}d overdue';
      } else {
        return 'Overdue';
      }
    } else {
      if (difference.inDays > 0) {
        return 'Due in ${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return 'Due in ${difference.inHours}h';
      } else {
        return 'Due soon';
      }
    }
  }
}
