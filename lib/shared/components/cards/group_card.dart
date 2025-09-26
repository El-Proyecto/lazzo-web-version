import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../../models/group_enums.dart';
import '../badges/group_badge.dart';
import '../../../features/groups/domain/entities/group.dart';

/// Card tokenizado para exibir informações de um grupo
class GroupCard extends StatefulWidget {
  final Group group;
  final VoidCallback? onTap;
  final Function(GlobalKey)? onLongPress;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _cardKey,
      onTap: widget.onTap,
      onLongPress: () => widget.onLongPress?.call(_cardKey),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.screenH,
          vertical: Gaps.sm,
        ),
        child: Row(
          children: [
            // Avatar do grupo
            _buildAvatar(),
            const SizedBox(width: Gaps.sm),

            // Conteúdo central (nome e sub-linha)
            Expanded(child: _buildContent()),

            const SizedBox(width: Gaps.sm),

            // Badges à direita
            _buildBadges(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: ShapeDecoration(
            color: BrandColors.bg3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.smAlt),
            ),
            image: widget.group.avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.group.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.group.avatarUrl == null
              ? const Icon(Icons.group, color: BrandColors.text2, size: 28)
              : null,
        ),

        // Ícones no canto superior do avatar
        if (widget.group.status == GroupStatus.archived)
          // Archived groups only show archive icon (archived groups can't be pinned or muted in UI)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: BrandColors.bg2,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(Radii.smAlt),
                  bottomLeft: Radius.circular(Radii.smAlt),
                ),
              ),
              child: const Icon(Icons.archive, size: 12, color: BrandColors.text2),
            ),
          )
        else ...[
          // Multiple icons for active groups
          if (widget.group.isPinned && widget.group.isMuted)
            // Both icons in same container
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: BrandColors.bg2,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(Radii.smAlt),
                    bottomLeft: Radius.circular(Radii.smAlt),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 12,
                      color: BrandColors.text2,
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.notifications_off,
                      size: 12,
                      color: BrandColors.text2,
                    ),
                  ],
                ),
              ),
            )
          else if (widget.group.isPinned)
            // Only pinned icon
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: BrandColors.bg2,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(Radii.smAlt),
                    bottomLeft: Radius.circular(Radii.smAlt),
                  ),
                ),
                child: const Icon(
                  Icons.push_pin,
                  size: 12,
                  color: BrandColors.text2,
                ),
              ),
            )
          else if (widget.group.isMuted)
            // Only muted icon
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: BrandColors.bg2,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(Radii.smAlt),
                    bottomLeft: Radius.circular(Radii.smAlt),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_off,
                  size: 12,
                  color: BrandColors.text2,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nome do grupo (sem o ícone de pin, agora está no avatar)
        Text(
          widget.group.name,
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: Gaps.xxs),

        // Sub-linha contextual
        Text(
          widget.group.contextualSubline,
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBadges() {
    final badgeData = <Map<String, dynamic>>[];

    // Badge para Open Actions - cor depende do tempo que falta
    if (widget.group.openActionsCount != null &&
        widget.group.openActionsCount! > 0) {
      badgeData.add({
        'widget': GroupBadge(
          icon: Icons.bolt, // Ícone de raio
          count: widget.group.openActionsCount!,
          urgency: _getOpenActionsUrgency(),
        ),
        'urgency': _getOpenActionsUrgency(),
        'priority': _urgencyToPriority(_getOpenActionsUrgency()),
      });
    }

    // Badge para Add Photos com tempo - só pode ser amarelo ou vermelho
    if (widget.group.addPhotosCount != null &&
        widget.group.addPhotosCount! > 0) {
      badgeData.add({
        'widget': GroupBadge(
          icon: Icons.camera_alt,
          text: widget.group.addPhotosTimeLeft ?? '12h',
          urgency: _getAddPhotosUrgency(),
        ),
        'urgency': _getAddPhotosUrgency(),
        'priority': _urgencyToPriority(_getAddPhotosUrgency()),
      });
    }

    // Badge para mensagens não lidas - sempre verde
    if (widget.group.unreadCount != null && widget.group.unreadCount! > 0) {
      badgeData.add({
        'widget': GroupBadge(
          icon: Icons.message,
          count: widget.group.unreadCount!,
          urgency: BadgeUrgency.low, // Sempre verde
        ),
        'urgency': BadgeUrgency.low,
        'priority': _urgencyToPriority(BadgeUrgency.low),
      });
    }

    if (badgeData.isEmpty) {
      return const SizedBox(width: 40);
    }

    // Ordenar por prioridade (menor número = maior prioridade)
    badgeData.sort((a, b) => a['priority'].compareTo(b['priority']));

    // Pegar apenas os 2 badges mais prioritários
    final topBadges = badgeData
        .take(2)
        .map((data) => data['widget'] as Widget)
        .toList();

    // Organizar badges alinhados à esquerda
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (int i = 0; i < topBadges.length; i++) ...[
          topBadges[i],
          if (i < topBadges.length - 1) const SizedBox(width: Gaps.xs),
        ],
      ],
    );
  }

  /// Calcula urgência dos Open Actions baseado no tempo restante
  BadgeUrgency _getOpenActionsUrgency() {
    // Simular lógica baseada no tempo - em implementação real seria baseado no deadline
    final timeText = widget.group.lastActivity ?? '';

    if (timeText.contains('closes') && timeText.contains('today')) {
      return BadgeUrgency.high; // Vermelho - fecha hoje
    } else if (timeText.contains('closes') && timeText.contains('Tuesday')) {
      return BadgeUrgency.medium; // Amarelo - fecha em breve
    } else if (timeText.contains('Vote') || timeText.contains('Decide')) {
      return BadgeUrgency.medium; // Amarelo - ação necessária
    }

    return BadgeUrgency.low; // Verde - não urgente
  }

  /// Converte urgência para prioridade numérica (menor = mais prioritário)
  int _urgencyToPriority(BadgeUrgency urgency) {
    switch (urgency) {
      case BadgeUrgency.high:
        return 1; // Vermelho - highest priority
      case BadgeUrgency.medium:
        return 2; // Amarelo - medium priority
      case BadgeUrgency.low:
        return 3; // Verde - lowest priority
      case BadgeUrgency.none:
        return 4; // Sem badge - lowest priority
    }
  }

  /// Calcula urgência do Add Photos baseado no tempo restante
  BadgeUrgency _getAddPhotosUrgency() {
    final timeLeft = widget.group.addPhotosTimeLeft ?? '';

    // Extrair horas do texto (ex: "4h", "18h")
    final hours = int.tryParse(timeLeft.replaceAll('h', '')) ?? 24;

    if (hours <= 6) {
      return BadgeUrgency.high; // Vermelho - menos de 6h
    } else {
      return BadgeUrgency.medium; // Amarelo - mais de 6h
    }
  }
}
