import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/rsvp.dart';
import '../providers/event_providers.dart';
import '../widgets/guest_vote_summary_card.dart';
import '../widgets/guest_list_tile.dart';

/// Page showing all event guests grouped and filterable by RSVP status.
/// Accessible from the event detail app bar via the members icon.
class ManageGuestsPage extends ConsumerStatefulWidget {
  final String eventId;

  const ManageGuestsPage({super.key, required this.eventId});

  @override
  ConsumerState<ManageGuestsPage> createState() => _ManageGuestsPageState();
}

class _ManageGuestsPageState extends ConsumerState<ManageGuestsPage> {
  /// Currently selected filter. Null means show all.
  RsvpStatus? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final rsvpsAsync = ref.watch(eventRsvpsProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Manage Guests',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.ios_share, color: BrandColors.text1),
          onPressed: () {
            final eventName = eventAsync.value?.name ?? 'this event';
            SharePlus.instance.share(
              ShareParams(text: 'Join $eventName on Lazzo! 🎉'),
            );
          },
        ),
      ),
      body: rsvpsAsync.when(
        data: (rsvps) => _buildContent(rsvps),
        loading: () => const Center(
          child: CircularProgressIndicator(color: BrandColors.planning),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Insets.screenH),
            child: Text(
              'Failed to load guests',
              style: AppText.bodyLarge.copyWith(color: BrandColors.text2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Rsvp> rsvps) {
    // Count votes by status (exclude pending)
    final goingCount = rsvps.where((r) => r.status == RsvpStatus.going).length;
    final maybeCount = rsvps.where((r) => r.status == RsvpStatus.maybe).length;
    final cantCount =
        rsvps.where((r) => r.status == RsvpStatus.notGoing).length;

    // Filter rsvps based on selected status
    final filteredRsvps = _selectedFilter != null
        ? rsvps.where((r) => r.status == _selectedFilter).toList()
        : rsvps.where((r) => r.status != RsvpStatus.pending).toList();

    // Sort by date, most recent first
    filteredRsvps.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        // Vote summary cards
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.screenH,
            vertical: Gaps.md,
          ),
          child: Row(
            children: [
              GuestVoteSummaryCard(
                label: 'Can',
                count: goingCount,
                countColor: BrandColors.planning,
                isSelected: _selectedFilter == RsvpStatus.going,
                onTap: () => _toggleFilter(RsvpStatus.going),
              ),
              const SizedBox(width: Gaps.xs),
              GuestVoteSummaryCard(
                label: 'Maybe',
                count: maybeCount,
                countColor: BrandColors.warning,
                isSelected: _selectedFilter == RsvpStatus.maybe,
                onTap: () => _toggleFilter(RsvpStatus.maybe),
              ),
              const SizedBox(width: Gaps.xs),
              GuestVoteSummaryCard(
                label: "Can't",
                count: cantCount,
                countColor: BrandColors.cantVote,
                isSelected: _selectedFilter == RsvpStatus.notGoing,
                onTap: () => _toggleFilter(RsvpStatus.notGoing),
              ),
            ],
          ),
        ),

        // Guest list
        Expanded(
          child: filteredRsvps.isEmpty
              ? _buildEmptyState()
              : Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: Insets.screenH,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColors.bg2,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: Pads.ctlV,
                      ),
                      itemCount: filteredRsvps.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: BrandColors.border.withValues(alpha: 0.3),
                        indent: Insets.screenH + 48 + Gaps.sm,
                        endIndent: Insets.screenH,
                      ),
                      itemBuilder: (context, index) {
                        return GuestListTile(
                          rsvp: filteredRsvps[index],
                        );
                      },
                    ),
                  ),
                ),
        ),

        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  Widget _buildEmptyState() {
    final filterLabel =
        _selectedFilter != null ? _filterLabel(_selectedFilter!) : 'guests';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.xl),
        child: Text(
          'No $filterLabel yet',
          style: AppText.bodyLarge.copyWith(color: BrandColors.text2),
        ),
      ),
    );
  }

  void _toggleFilter(RsvpStatus status) {
    setState(() {
      _selectedFilter = _selectedFilter == status ? null : status;
    });
  }

  String _filterLabel(RsvpStatus status) {
    switch (status) {
      case RsvpStatus.going:
        return '"Can" votes';
      case RsvpStatus.maybe:
        return '"Maybe" votes';
      case RsvpStatus.notGoing:
        return '"Can\'t" votes';
      case RsvpStatus.pending:
        return 'pending guests';
    }
  }
}
