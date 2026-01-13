import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter/foundation.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/inputs/search_bar.dart' as custom;
import '../../../../shared/components/cards/group_card.dart';
import 'package:lazzo/config/app_config.dart';
import 'package:lazzo/features/group_invites/presentation/providers/group_invites_providers.dart';
import 'package:lazzo/shared/components/common/invite_bottom_sheet.dart';
import '../widgets/group_context_menu.dart';
import '../../../../shared/models/group_enums.dart';
import '../../../../shared/components/chips/filter_chip.dart';
import '../../domain/entities/group.dart';
import '../providers/groups_provider.dart';
import '../../../../routes/app_router.dart';
import '../../../group_hub/presentation/providers/group_hub_providers.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  GroupFilter _selectedFilter = GroupFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Force refresh groups every time the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsControllerProvider).refreshGroups();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh groups when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      ref.read(groupsControllerProvider).refreshGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use different providers based on selected filter
    final groupsAsync = _selectedFilter == GroupFilter.archived
        ? ref.watch(archivedGroupsProvider)
        : ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar.groups(
        onCreateGroupPressed: _handleCreateGroup,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
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

          // Filtros sempre visíveis
          Padding(
            padding: const EdgeInsets.only(
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
                const SizedBox(width: Gaps.sm),
                // Actions filter removed from MVP (P1 only - awaiting P2 backend)
                CustomFilterChip(
                  label: 'Archived',
                  isSelected: _selectedFilter == GroupFilter.archived,
                  onTap: () => setState(
                    () => _selectedFilter = GroupFilter.archived,
                  ),
                ),
              ],
            ),
          ),

          // Lista de grupos
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                var filteredGroups = groups;

                // Para filtro archived, já vem do provider correto, não precisa filtrar
                if (_selectedFilter != GroupFilter.archived) {
                  // Aplicar filtro por status (apenas para All e Actions)
                  filteredGroups = _applyStatusFilter(filteredGroups);
                }

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

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(groupsControllerProvider).refreshGroups();
                  },
                  color: BrandColors.planning,
                  backgroundColor: BrandColors.bg2,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount:
                        filteredGroups.length, // Apenas grupos, filtros fora
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      return GroupCard(
                        group: group,
                        onTap: () => _handleGroupTap(group.id),
                        onLongPress: (cardKey) =>
                            _handleGroupLongPress(context, group.id, cardKey),
                      );
                    },
                  ),
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
          const Icon(Icons.group_outlined, size: 64, color: BrandColors.text2),
          const SizedBox(height: Gaps.md),
          Text(
            _searchQuery.isEmpty ? 'No groups yet' : 'No groups found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: BrandColors.text2),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: Gaps.sm),
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
    return const Center(
      child: CircularProgressIndicator(color: BrandColors.planning),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: BrandColors.cantVote,
          ),
          const SizedBox(height: Gaps.md),
          Text(
            'Error loading groups',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: BrandColors.cantVote),
          ),
          const SizedBox(height: Gaps.sm),
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
    Navigator.of(context).pushNamed('/create-group');
  }

  Future<void> _handleGroupTap(String groupId) async {
    // Find the group in the current list to get its details
    final groupsAsync = _selectedFilter == GroupFilter.archived
        ? ref.read(archivedGroupsProvider)
        : ref.read(groupsProvider);
    final groups = groupsAsync.value ?? [];
    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => const Group(
        id: '',
        name: '',
        status: GroupStatus.active,
        memberCount: 0,
      ),
    );

    if (group.id.isNotEmpty) {
      // Convert storage path to signed URL before navigation
      String? groupPhotoUrl;
      if (group.photoPath != null) {
        final photoUrlAsync = await ref.read(
          groupCoverUrlProvider((group.photoPath, group.photoUpdatedAt)).future,
        );
        groupPhotoUrl = photoUrlAsync;
      }

      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRouter.groupHub,
          arguments: {
            'groupId': group.id,
            'groupName': group.name,
            'groupPhotoUrl': groupPhotoUrl,
          },
        );
      }
    }
  }

  void _handleGroupLongPress(
    BuildContext context,
    String groupId,
    GlobalKey cardKey,
  ) {
    // Encontra o grupo na lista atual (baseado no filtro selecionado)
    final groupsAsync = _selectedFilter == GroupFilter.archived
        ? ref.read(archivedGroupsProvider)
        : ref.read(groupsProvider);
    final groups = groupsAsync.value ?? [];
    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => const Group(
        id: '',
        name: '',
        status: GroupStatus.active,
        memberCount: 0,
      ),
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

      // Open Actions removed from MVP (P1 only - awaiting P2 backend)
      // openActionsCount preserved in Group entity for future use

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
    Navigator.of(
      context,
    ).pushNamed('/create-event', arguments: {'groupId': groupId});
  }

  void _handleInvite(String groupId) async {
    // Create invite link and show bottom sheet
    try {
      final createInvite = ref.read(createGroupInviteLinkProvider);
      // fire-and-forget: create invite then show bottom sheet
      createInvite.call(groupId: groupId).then((result) {
        final inviteUrl = '${AppConfig.invitesBaseUrl}/i/${result.token}';

        final groupsAsync = _selectedFilter == GroupFilter.archived
            ? ref.read(archivedGroupsProvider)
            : ref.read(groupsProvider);
        final groups = groupsAsync.value ?? [];
        final group = groups.firstWhere(
          (g) => g.id == groupId,
          orElse: () => const Group(
            id: '',
            name: '',
            status: GroupStatus.active,
            memberCount: 0,
          ),
        );

        InviteBottomSheet.show(
          context: context,
          inviteUrl: inviteUrl,
          entityName: group.name.isNotEmpty ? group.name : 'Group',
          entityType: 'group',
        );
      }).catchError((error) {
        // fallback: use group ID path
        final inviteUrl = '${AppConfig.invitesBaseUrl}/groups/$groupId';

        InviteBottomSheet.show(
          context: context,
          inviteUrl: inviteUrl,
          entityName: 'Group',
          entityType: 'group',
        );
      });
    } catch (e) {
      final inviteUrl = '${AppConfig.invitesBaseUrl}/groups/$groupId';

      InviteBottomSheet.show(
        context: context,
        inviteUrl: inviteUrl,
        entityName: 'Group',
        entityType: 'group',
      );
    }
  }

  // MVP: Actions removed, preserved for P2 implementation
  // void _handleOpenActions(String groupId) {
  //   // Navegar para o filtro de actions
  //   setState(() {
  //     _selectedFilter = GroupFilter.actions;
  //   });
  // }

  void _handleMute(String groupId) {
    final controller = ref.read(groupsControllerProvider);

    // Busca o grupo na lista atual (baseado no filtro selecionado)
    final groupsAsync = _selectedFilter == GroupFilter.archived
        ? ref.read(archivedGroupsProvider)
        : ref.read(groupsProvider);
    final groups = groupsAsync.value ?? [];
    final group = groups.firstWhere((g) => g.id == groupId);

    // Toggle: se está muted, vai unmute (false), se não está muted, vai mute (true)
    final newMutedState = !group.isMuted;
    controller.toggleMute(groupId, newMutedState);

    // Invalidate group details to sync mute state
    ref.invalidate(groupDetailsProvider(groupId));
  }

  void _handleLeaveGroup(String groupId) {
    // Busca o nome do grupo para mostrar no diálogo
    final groupsAsync = _selectedFilter == GroupFilter.archived
        ? ref.read(archivedGroupsProvider)
        : ref.read(groupsProvider);
    final groups = groupsAsync.value ?? [];
    final group = groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => const Group(
        id: '',
        name: 'Unknown Group',
        status: GroupStatus.active,
        memberCount: 0,
      ),
    );

    // Mostra diálogo de confirmação
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: BrandColors.bg1,
          title: Text(
            'Leave Group',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: BrandColors.text1,
                ),
          ),
          content: Text(
            'Are you sure you want to leave "${group.name}"?\n\nThis action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BrandColors.text2,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: BrandColors.text2),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // OPTIMISTIC UI: Remove group from list immediately
                final controller = ref.read(groupsControllerProvider);

                try {
                  // Call server in background
                  await controller.leaveGroupOptimistic(groupId);

                  // Show success feedback
                  if (!mounted) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Left "${group.name}"'),
                        backgroundColor: BrandColors.planning,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Show error feedback (rollback already happened in controller)
                  if (!mounted) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Failed to leave group: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: BrandColors.cantVote,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Leave',
                style: TextStyle(color: BrandColors.cantVote),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleArchive(String groupId) {
    final controller = ref.read(groupsControllerProvider);
    controller.toggleArchive(groupId);

    // Não redirecionar automaticamente - deixar user escolher quando ver
  }

  void _handlePin(String groupId) {
    final controller = ref.read(groupsControllerProvider);
    controller.togglePin(groupId);
  }

  /// Aplica filtro por status dos grupos (apenas para All e Actions)
  List<Group> _applyStatusFilter(List<Group> groups) {
    switch (_selectedFilter) {
      case GroupFilter.all:
        // Retorna todos os grupos ativos (não arquivados)
        return groups
            .where((group) => group.status != GroupStatus.archived)
            .toList();
      case GroupFilter.actions:
        // Retorna apenas grupos ativos com ações abertas
        return groups
            .where(
              (group) =>
                  group.status != GroupStatus.archived &&
                  (group.openActionsCount != null &&
                      group.openActionsCount! > 0),
            )
            .toList();
      case GroupFilter.archived:
        // Este caso não deve ser chamado, pois usar o archivedGroupsProvider
        return groups;
    }
  }

  /// Ordena grupos por prioridade baseado nos badges
  /// Prioridade: Afixados > Vermelhos > Amarelos > Verdes
  List<Group> _sortGroupsByPriority(List<Group> groups) {
    return List.from(groups)
      ..sort((a, b) {
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
