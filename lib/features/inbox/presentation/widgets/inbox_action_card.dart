import 'package:flutter/material.dart';
import '../../domain/entities/action.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class InboxActionCard extends StatelessWidget {
  final ActionEntity action;
  final VoidCallback? onTap;

  const InboxActionCard({super.key, required this.action, this.onTap});

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
        child: Column(
          children: [
            _buildTopSection(),
            const SizedBox(height: Gaps.md),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Row(
      children: [
        _buildEventIcon(),
        const SizedBox(width: Gaps.sm), // Reduzido para metade (era md)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getActionTitle(),
                style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
              ),
              const SizedBox(
                height: Gaps.xs / 4,
              ), // Reduzido para metade (era xs/2)
              Text(
                _getEventName(),
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
            ],
          ),
        ),
        const SizedBox(width: Gaps.sm), // Reduzido para metade (era md)
        const Icon(
          Icons.chevron_right,
          color: BrandColors.text2,
          size: IconSizes.md,
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Row(
      children: [
        _buildGroupIcon(),
        const SizedBox(width: Gaps.xs), // Reduzido para metade (era sm)
        Text(
          _getGroupName(),
          style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
        ),
        const Spacer(),
        _buildTimeLeftIndicator(),
      ],
    );
  }

  Widget _buildEventIcon() {
    // Calculo da altura baseado no título + subtítulo + gap
    // titleMediumEmph ≈ 20px + bodyMedium ≈ 16px + gap ≈ 2px = 38px
    // Arredondando para 40px para ficar proporcional
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Text(
          _getEventEmoji(),
          style: const TextStyle(
            fontSize: 28,
          ), // Aumentado para ficar proporcional
        ),
      ),
    );
  }

  Widget _buildGroupIcon() {
    return const Icon(
      Icons.group,
      color: BrandColors.text2,
      size: IconSizes.sm,
    );
  }

  Widget _buildTimeLeftIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, color: _getTimeLeftColor(), size: IconSizes.sm),
        const SizedBox(width: Gaps.xs / 2), // Reduzido para metade (era xs)
        Text(
          action.deadlineText ?? 'No deadline',
          style: AppText.labelLarge.copyWith(color: BrandColors.text1),
        ),
      ],
    );
  }

  String _getActionTitle() {
    switch (action.type) {
      case ActionType.voteDate:
        return action.formattedDescription;
      case ActionType.votePlace:
        return action.formattedDescription;
      case ActionType.confirmAttendance:
        return action.formattedDescription;
      case ActionType.completeDetails:
        return action.formattedDescription;
      case ActionType.addPhotos:
        return action.formattedDescription;
      // Legacy action types for backward compatibility
      case ActionType.vote:
        return 'Vote on a local';
      case ActionType.rsvp:
        return 'Confirm attendance';
      case ActionType.payment:
        return 'Pay for tickets';
      case ActionType.taskAssignment:
        return 'Bring decorations';
      case ActionType.eventPreparation:
        return 'Import photos';
    }
  }

  String _getEventName() {
    // O subtítulo é sempre o nome do evento
    // Em produção, viria de uma entidade Event linkada pelo eventId
    // Para demo, usando nomes baseados no emoji/tipo da atividade
    if (action.eventEmoji != null) {
      switch (action.eventEmoji) {
        case '🍽️':
          return 'Friday Dinner';
        case '🏖️':
          return 'Beach BBQ';
        case '🎵':
          return 'Concert Night';
        case '🎂':
          return 'Birthday Party';
        default:
          return 'Event Name';
      }
    }

    // Fallback baseado no tipo
    switch (action.type) {
      case ActionType.voteDate:
      case ActionType.votePlace:
        return 'Restaurant Choice';
      case ActionType.confirmAttendance:
        return 'Beach BBQ';
      case ActionType.completeDetails:
        return 'Event Planning';
      case ActionType.addPhotos:
        return 'Photo Sharing';
      // Legacy types
      case ActionType.vote:
        return 'Restaurant Choice';
      case ActionType.rsvp:
        return 'Beach BBQ';
      case ActionType.payment:
        return 'Concert Tickets';
      case ActionType.taskAssignment:
        return 'Birthday Party';
      case ActionType.eventPreparation:
        return 'Photo Sharing';
    }
  }

  String _getGroupName() {
    // In a real app, this would come from a Group entity via groupId
    // For now, we'll use intelligent mapping based on groupId
    switch (action.groupId) {
      case 'group1':
        return 'Dinner Group';
      case 'group2':
        return 'Beach Friends';
      case 'group3':
        return 'Weekend Hikers';
      default:
        return 'Unknown Group';
    }
  }

  String _getEventEmoji() {
    // Se tiver emoji do evento específico, usa esse
    if (action.eventEmoji != null && action.eventEmoji!.isNotEmpty) {
      return action.eventEmoji!;
    }

    // Fallback para emojis genéricos por tipo (só se não tiver emoji específico)
    switch (action.type) {
      case ActionType.voteDate:
      case ActionType.votePlace:
        return '🗳️';
      case ActionType.confirmAttendance:
        return '📅';
      case ActionType.completeDetails:
        return '📋';
      case ActionType.addPhotos:
        return '📸';
      // Legacy types
      case ActionType.vote:
        return '🗳️';
      case ActionType.rsvp:
        return '📅';
      case ActionType.payment:
        return '💳';
      case ActionType.taskAssignment:
        return '📋';
      case ActionType.eventPreparation:
        return '📸';
    }
  }

  Color _getTimeLeftColor() {
    if (action.isOverdue) {
      return BrandColors.cantVote; // Red
    }

    final timeLeft = action.timeLeft;
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
