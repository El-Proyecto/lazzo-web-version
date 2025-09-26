import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../forms/event_group_selector.dart';
import '../widgets/grabber_bar.dart';

/// Bottom sheet para pesquisar e selecionar grupos
/// Inclui barra de pesquisa e opção para criar novo grupo
class GroupSelectionBottomSheet extends StatefulWidget {
  final List<GroupInfo> groups;
  final Function(GroupInfo)? onGroupSelected;
  final VoidCallback? onCreateGroup;

  const GroupSelectionBottomSheet({
    super.key,
    required this.groups,
    this.onGroupSelected,
    this.onCreateGroup,
  });

  @override
  State<GroupSelectionBottomSheet> createState() =>
      _GroupSelectionBottomSheetState();
}

class _GroupSelectionBottomSheetState extends State<GroupSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<GroupInfo> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _filteredGroups = widget.groups;
    _searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGroups = widget.groups
          .where((group) => group.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: keyboardHeight > 0 ? maxHeight : 500,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber bar
          const Padding(
            padding: EdgeInsets.only(top: Gaps.sm),
            child: Center(child: GrabberBar()),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Group',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: BrandColors.text2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content with padding
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                left: Gaps.lg,
                right: Gaps.lg,
                bottom: Gaps.lg + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barra de pesquisa
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: AppText.bodyLarge.copyWith(
                            color: BrandColors.text1,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search groups...',
                            hintStyle: AppText.bodyLarge.copyWith(
                              color: BrandColors.text2,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: BrandColors.text2,
                            ),
                            filled: true,
                            fillColor: BrandColors.bg3,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(Radii.smAlt),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Pads.ctlH,
                              vertical: Pads.ctlV,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: Gaps.sm),

                      // Botão criar grupo
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onCreateGroup?.call();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: BrandColors.planning,
                            borderRadius: BorderRadius.circular(Radii.smAlt),
                          ),
                          child: const Icon(
                            Icons.group_add,
                            color: BrandColors.text1,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Gaps.md),

                  // Lista de grupos
                  Flexible(
                    child: _filteredGroups.isEmpty
                        ? _EmptyState(
                            hasSearchTerm: _searchController.text.isNotEmpty,
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: _filteredGroups.length,
                            itemBuilder: (context, index) {
                              final group = _filteredGroups[index];
                              return _GroupTile(
                                group: group,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onGroupSelected?.call(group);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupInfo group;
  final VoidCallback? onTap;

  const _GroupTile({required this.group, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Ícone do grupo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: group.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: Image.network(
                      group.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _DefaultGroupAvatar(name: group.name);
                      },
                    ),
                  )
                : _DefaultGroupAvatar(name: group.name),
          ),

          const SizedBox(height: Gaps.xs),

          // Nome do grupo
          Text(
            group.name,
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text1,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Número de membros
          Text(
            '${group.memberCount} members',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DefaultGroupAvatar extends StatelessWidget {
  final String name;

  const _DefaultGroupAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'G',
        style: AppText.titleMediumEmph.copyWith(
          color: BrandColors.text1,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearchTerm;

  const _EmptyState({required this.hasSearchTerm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearchTerm ? Icons.search_off : Icons.group,
            color: BrandColors.text2,
            size: 48,
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            hasSearchTerm ? 'No groups found' : 'No groups available',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
          if (!hasSearchTerm) ...[
            const SizedBox(height: Gaps.sm),
            Text(
              'Create your first group!',
              style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
            ),
          ],
        ],
      ),
    );
  }
}
