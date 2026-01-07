import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/buttons/green_button.dart';
import '../../../../shared/components/chips/group_chip.dart';

/// Model for group data in the chip list
class GroupChipData {
  final String id;
  final String name;
  final String? photoUrl;

  const GroupChipData({
    required this.id,
    required this.name,
    this.photoUrl,
  });
}

/// Empty state card shown when user has groups but no upcoming events
/// Feature-specific widget for Home page
class NoUpcomingEventsCard extends StatefulWidget {
  final List<GroupChipData> groups;
  final Function(String groupId) onCreateEvent;
  final VoidCallback? onDismiss;

  const NoUpcomingEventsCard({
    super.key,
    required this.groups,
    required this.onCreateEvent,
    this.onDismiss,
  });

  @override
  State<NoUpcomingEventsCard> createState() => _NoUpcomingEventsCardState();
}

class _NoUpcomingEventsCardState extends State<NoUpcomingEventsCard> {
  String? _selectedGroupId;
  final ScrollController _scrollController = ScrollController();
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    // Auto-select first group always (as default)
    if (widget.groups.isNotEmpty) {
      _selectedGroupId = widget.groups.first.id;
    }

    // Add scroll listener to update fade visibility
    _scrollController.addListener(_updateFadeVisibility);

    // Check initial fade state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFadeVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFadeVisibility() {
    if (!mounted) return;
    
    // Check if controller is attached before accessing position
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    setState(() {
      _showLeftFade = position.pixels > 0;
      _showRightFade = position.pixels < position.maxScrollExtent;
    });
  }

  String get _buttonText {
    if (_selectedGroupId != null && widget.groups.length == 1) {
      final group = widget.groups.first;
      return 'Create event for ${group.name}';
    }
    return 'Create event';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with close button
          Row(
            children: [
              Expanded(
                child: Text(
                  'No plans coming up',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
              ),
              if (widget.onDismiss != null)
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    padding: const EdgeInsets.all(Gaps.xxs),
                    child: const Icon(
                      Icons.close,
                      size: IconSizes.smAlt,
                      color: BrandColors.text2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gaps.xs),

          // Subtitle
          Text(
            'Pick a group and propose the next date.',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
          const SizedBox(height: Gaps.md),

          // Group chips with conditional fade edges (only show if more than one group)
          if (widget.groups.length > 1) ...[
            SizedBox(
              height: 36,
              child: Stack(
                children: [
                  // Scrollable chips
                  ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.groups.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: Gaps.xs),
                    itemBuilder: (context, index) {
                      final group = widget.groups[index];
                      return GroupChip(
                        groupName: group.name,
                        groupPhotoUrl: group.photoUrl,
                        isSelected: _selectedGroupId == group.id,
                        onTap: () {
                          setState(() {
                            _selectedGroupId = group.id;
                          });
                        },
                      );
                    },
                  ),
                  // Left fade - only show when scrolled right
                  if (_showLeftFade)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: IconSizes.smAlt,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                BrandColors.bg2,
                                BrandColors.bg2.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Right fade - only show when there's more content to scroll
                  if (_showRightFade)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: IconSizes.smAlt,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                BrandColors.bg2,
                                BrandColors.bg2.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Gaps.md),
          ],

          // CTA Button
          GreenButton(
            text: _buttonText,
            onPressed: _selectedGroupId != null
                ? () => widget.onCreateEvent(_selectedGroupId!)
                : null,
          ),
          const SizedBox(height: Gaps.xs),

          // Helper text
          Text(
            'Events are shared with group members.',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
              fontSize:
                  12,
            ),
          ),
        ],
      ),
    );
  }
}
