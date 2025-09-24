import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/components/nav/groups_app_bar.dart';
import '../../../../shared/components/inputs/search_bar.dart' as custom;
import '../../../../shared/components/cards/group_card.dart';
import '../../../../shared/components/dialogs/group_context_menu.dart';
import '../../../../shared/models/group_enums.dart';
import '../../../../shared/components/chips/filter_chip.dart';
import '../../domain/entities/group.dart';
import '../providers/groups_provider.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  String _searchQuery = '';
  GroupFilter _selectedFilter = GroupFilter.all;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: GroupsAppBar(onCreateGroupPressed: _handleCreateGroup),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Insets.screenH,
              vertical: Gaps.md,
            ),
            child: custom.SearchBar(
              placeholder: 'Search groups...',
              value: _searchQuery,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Lista de grupos com filtros incluídos na lista para rolagem
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                var filteredGroups = groups;

                // Aplicar filtro por status
                filteredGroups = _applyStatusFilter(filteredGroups);

                // Aplicar filtro de busca
                if (_searchQuery.isNotEmpty) {
                  filteredGroups = filteredGroups
                      .where(
                        (group) => group.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
                }

                // Ordenar por prioridade (vermelhos > amarelo > verde)
                filteredGroups = _sortGroupsByPriority(filteredGroups);

                if (filteredGroups.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredGroups.length + 1, // +1 para os filtros
                  itemBuilder: (context, index) {
                    // Primeiro item é a linha de filtros
                    if (index == 0) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: Insets.screenH,
                          right: Insets.screenH,
                          bottom: Gaps.xs,
                        ),
                        child: Row(
                          children: [
                            CustomFilterChip(
                              label: 'All',
                              isSelected: _selectedFilter == GroupFilter.all,
                              onTap: () => setState(
                                () => _selectedFilter = GroupFilter.all,
                              ),
                            ),
                            SizedBox(width: Gaps.sm),
                            CustomFilterChip(
                              label: 'Actions',
                              isSelected:
                                  _selectedFilter == GroupFilter.actions,
                              onTap: () => setState(
                                () => _selectedFilter = GroupFilter.actions,
                              ),
                            ),
                            SizedBox(width: Gaps.sm),
                            CustomFilterChip(
                              label: 'Archived',
                              isSelected:
                                  _selectedFilter == GroupFilter.archived,
                              onTap: () => setState(
                                () => _selectedFilter = GroupFilter.archived,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Os demais itens são os grupos
                    final group =
                        filteredGroups[index -
                            1]; // -1 para compensar o índice dos filtros
                    return GroupCard(
                      group: group,
                      onTap: () => _handleGroupTap(group.id),
                      onLongPress: (cardKey) =>
                          _handleGroupLongPress(context, group.id, cardKey),
                    );
                  },
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stackTrace) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: BrandColors.text2),
          SizedBox(height: Gaps.md),
          Text(
            _searchQuery.isEmpty ? 'No groups yet' : 'No groups found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: BrandColors.text2),
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: Gaps.sm),
            Text(
              'Create your first group to get started',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: BrandColors.text2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: BrandColors.planning),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: BrandColors.cantVote),
          SizedBox(height: Gaps.md),
          Text(
            'Error loading groups',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: BrandColors.cantVote),
          ),
          SizedBox(height: Gaps.sm),
          Text(
            error.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: BrandColors.text2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleCreateGroup() {
    // TODO: Implementar navegação para criar grupo
    print('Create group pressed');
  }

  void _handleGroupTap(String groupId) {
    // TODO: Implementar navegação para o grupo
    print('Group tapped: $groupId');
  }

  void _handleGroupLongPress(
    BuildContext context,
    String groupId,
    GlobalKey cardKey,
  ) {
    // Encontra o grupo atual na lista
    final groupsAsync = ref.read(groupsProvider);
    final groups = groupsAsync.value ?? [];
    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () =>
          Group(id: '', name: '', status: GroupStatus.active, memberCount: 0),
    );

    // Ajusta o menu com base no estado atual do grupo
    final actions = <GroupMenuAction>[
      GroupMenuAction(
        title: 'Create event',
        icon: Icons.add, // Ícone de + para criar evento
        onTap: () => _handleCreateEvent(groupId),
      ),
      GroupMenuAction(
        title: 'Invite',
        icon: Icons.person_add,
        onTap: () => _handleInvite(groupId),
      ),

      // Open Actions - só aparece se o grupo tem ações abertas
      if (group.openActionsCount != null && group.openActionsCount! > 0)
        GroupMenuAction(
          title: 'Open Actions',
          icon: Icons.bolt, // Ícone de raio para Open Actions
          onTap: () => _handleOpenActions(groupId),
        ),

      // Mute/Unmute - não aparece em grupos arquivados
      if (group.status != GroupStatus.archived)
        GroupMenuAction(
          title: group.isMuted ? 'Unmute' : 'Mute',
          icon: group.isMuted ? Icons.notifications : Icons.notifications_off,
          onTap: () => _handleMute(groupId),
        ),

      // Pin/Unpin - não aparece em grupos arquivados
      if (group.status != GroupStatus.archived)
        GroupMenuAction(
          title: group.isPinned ? 'Unpin' : 'Pin',
          icon: Icons.push_pin,
          onTap: () => _handlePin(groupId),
        ),

      GroupMenuAction(
        title: group.status == GroupStatus.archived ? 'Unarchive' : 'Archive',
        icon: Icons.archive,
        onTap: () => _handleArchive(groupId),
      ),
      GroupMenuAction(
        title: 'Leave Group',
        icon: Icons.exit_to_app,
        onTap: () => _handleLeaveGroup(groupId),
        isDestructive: true,
      ),
    ];

    GroupContextMenu.show(context: context, actions: actions, cardKey: cardKey);
  }

  void _handleCreateEvent(String groupId) {
    print('Create event for group: $groupId');
    Navigator.of(
      context,
    ).pushNamed('/create-event', arguments: {'groupId': groupId});
  }

  void _handleInvite(String groupId) {
    print('Invite to group: $groupId');
  }

  void _handleOpenActions(String groupId) {
    print('Open actions for group: $groupId');
  }

  void _handleMute(String groupId) {
    print('Toggle mute for group: $groupId');
    final controller = ref.read(groupsControllerProvider);
    final groups = ref.read(groupsProvider).value ?? [];
    final group = groups.firstWhere((g) => g.id == groupId);
    controller.toggleMute(groupId, group.isMuted);
  }

  void _handleLeaveGroup(String groupId) {
    print('Leave group: $groupId');
  }

  void _handleArchive(String groupId) {
    print('Toggle archive for group: $groupId');
    final controller = ref.read(groupsControllerProvider);
    controller.toggleArchive(groupId);
  }

  void _handlePin(String groupId) {
    print('Toggle pin for group: $groupId');
    final controller = ref.read(groupsControllerProvider);
    controller.togglePin(groupId);
  }

  /// Aplica filtro por status dos grupos
  List<Group> _applyStatusFilter(List<Group> groups) {
    switch (_selectedFilter) {
      case GroupFilter.all:
        return groups
            .where((group) => group.status != GroupStatus.archived)
            .toList();
      case GroupFilter.actions:
        return groups
            .where(
              (group) =>
                  group.status != GroupStatus.archived &&
                  (group.openActionsCount != null &&
                      group.openActionsCount! > 0),
            )
            .toList();
      case GroupFilter.archived:
        return groups
            .where((group) => group.status == GroupStatus.archived)
            .toList();
    }
  }

  /// Ordena grupos por prioridade baseado nos badges
  /// Prioridade: Afixados > Vermelhos > Amarelos > Verdes
  List<Group> _sortGroupsByPriority(List<Group> groups) {
    return List.from(groups)..sort((a, b) {
      // Primeiro critério: grupos afixados sempre primeiro em qualquer categoria
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Segundo critério: ordenar por prioridade dos badges
      final priorityA = _getGroupPriority(a);
      final priorityB = _getGroupPriority(b);

      // Ordenar por prioridade decrescente (3=vermelho, 2=amarelo, 1=verde, 0=sem badges)
      if (priorityA != priorityB) {
        return priorityB.compareTo(priorityA);
      }

      // Terceiro critério: ordenar alfabeticamente pelo nome
      return a.name.compareTo(b.name);
    });
  }

  /// Calcula a prioridade máxima de um grupo baseado nos seus badges
  int _getGroupPriority(Group group) {
    int maxPriority = 0;

    // Open Actions - pode ser vermelho, amarelo ou verde
    if (group.openActionsCount != null && group.openActionsCount! > 0) {
      final urgency = _getOpenActionsUrgency(group);
      maxPriority = _max(maxPriority, _urgencyToPriority(urgency));
    }

    // Add Photos - só pode ser vermelho ou amarelo
    if (group.addPhotosCount != null && group.addPhotosCount! > 0) {
      final urgency = _getAddPhotosUrgency(group);
      maxPriority = _max(maxPriority, _urgencyToPriority(urgency));
    }

    // Mensagens não lidas - sempre verde
    if (group.unreadCount != null && group.unreadCount! > 0) {
      maxPriority = _max(maxPriority, 1); // Verde
    }

    return maxPriority;
  }

  /// Converte urgência para prioridade numérica
  int _urgencyToPriority(BadgeUrgency urgency) {
    switch (urgency) {
      case BadgeUrgency.high:
        return 3; // Vermelho
      case BadgeUrgency.medium:
        return 2; // Amarelo
      case BadgeUrgency.low:
        return 1; // Verde
      case BadgeUrgency.none:
        return 0; // Sem badge
    }
  }

  /// Calcula urgência dos Open Actions baseado no tempo restante
  BadgeUrgency _getOpenActionsUrgency(Group group) {
    final timeText = group.lastActivity ?? '';

    if (timeText.contains('closes') && timeText.contains('today')) {
      return BadgeUrgency.high; // Vermelho - fecha hoje
    } else if (timeText.contains('closes') && timeText.contains('Tuesday')) {
      return BadgeUrgency.medium; // Amarelo - fecha em breve
    } else if (timeText.contains('Vote') || timeText.contains('Decide')) {
      return BadgeUrgency.medium; // Amarelo - ação necessária
    }

    return BadgeUrgency.low; // Verde - não urgente
  }

  /// Calcula urgência do Add Photos baseado no tempo restante
  BadgeUrgency _getAddPhotosUrgency(Group group) {
    final timeLeft = group.addPhotosTimeLeft ?? '';

    // Extrair horas do texto (ex: "4h", "18h")
    final hours = int.tryParse(timeLeft.replaceAll('h', '')) ?? 24;

    if (hours <= 6) {
      return BadgeUrgency.high; // Vermelho - menos de 6h
    } else {
      return BadgeUrgency.medium; // Amarelo - mais de 6h
    }
  }

  int _max(int a, int b) => a > b ? a : b;
}
