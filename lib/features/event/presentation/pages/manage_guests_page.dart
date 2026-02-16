import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/rsvp.dart';
import '../providers/event_providers.dart';
import '../providers/event_photo_providers.dart';
import '../widgets/guest_vote_summary_card.dart';
import '../widgets/guest_list_tile.dart';

/// Page showing all event guests grouped and filterable by RSVP status.
/// In living mode: shows photo + participant counts and member photo contributions.
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
    final isLiving = eventAsync.value?.status == EventStatus.living;

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: isLiving ? 'Guests' : 'Manage Guests',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: isLiving
            ? null
            : IconButton(
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
        data: (rsvps) =>
            isLiving ? _buildLivingContent(rsvps) : _buildContent(rsvps),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: isLiving ? BrandColors.living : BrandColors.planning,
          ),
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

  // ─── Living Mode ──────────────────────────────────────────

  Widget _buildLivingContent(List<Rsvp> rsvps) {
    final photosAsync = ref.watch(eventPhotosProvider(widget.eventId));
    final photos = photosAsync.value ?? [];

    // Count total photos and participants (going only)
    final totalPhotos = photos.length;
    final goingRsvps =
        rsvps.where((r) => r.status == RsvpStatus.going).toList();
    final participantCount = goingRsvps.length;

    // Build per-user photo counts from photos data
    final photoCountByUser = <String, int>{};
    for (final photo in photos) {
      final uploaderId = photo['uploader_id'] as String? ?? '';
      if (uploaderId.isNotEmpty) {
        photoCountByUser[uploaderId] = (photoCountByUser[uploaderId] ?? 0) + 1;
      }
    }

    // Build participant list with photo counts — all going participants
    final participantEntries = goingRsvps.map((rsvp) {
      return _ParticipantEntry(
        userId: rsvp.userId,
        userName: rsvp.userName,
        userAvatar: rsvp.userAvatar,
        photoCount: photoCountByUser[rsvp.userId] ?? 0,
      );
    }).toList();

    // Sort by photo count descending, then alphabetically
    participantEntries.sort((a, b) {
      final countCmp = b.photoCount.compareTo(a.photoCount);
      if (countCmp != 0) return countCmp;
      return a.userName.compareTo(b.userName);
    });

    return Column(
      children: [
        // Summary cards: Photos + Participants
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.screenH,
            vertical: Gaps.md,
          ),
          child: Row(
            children: [
              _LivingSummaryCard(
                icon: Icons.photo_library_outlined,
                count: totalPhotos,
                label: 'Photos',
              ),
              const SizedBox(width: Gaps.xs),
              _LivingSummaryCard(
                icon: Icons.people_outline,
                count: participantCount,
                label: 'Participants',
              ),
            ],
          ),
        ),

        // Participant list with photo counts
        Expanded(
          child: participantEntries.isEmpty
              ? _buildLivingEmptyState()
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
                      itemCount: participantEntries.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: BrandColors.border.withValues(alpha: 0.3),
                        indent: Insets.screenH + 48 + Gaps.sm,
                        endIndent: Insets.screenH,
                      ),
                      itemBuilder: (context, index) {
                        final entry = participantEntries[index];
                        return _LivingParticipantTile(entry: entry);
                      },
                    ),
                  ),
                ),
        ),

        const SizedBox(height: Gaps.lg),
      ],
    );
  }

  Widget _buildLivingEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Insets.screenH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gaps.xl),
          child: Text(
            'No participants yet',
            style: AppText.bodyLarge.copyWith(color: BrandColors.text2),
          ),
        ),
      ),
    );
  }

  // ─── Default Mode (Planning/Confirmed) ────────────────────

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
                        final rsvp = filteredRsvps[index];
                        return GuestListTile(
                          rsvp: rsvp,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.otherProfile,
                              arguments: {'userId': rsvp.userId},
                            );
                          },
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
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Insets.screenH,
      ),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gaps.xl),
          child: Text(
            'No $filterLabel yet',
            style: AppText.bodyLarge.copyWith(color: BrandColors.text2),
          ),
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

// ─── Living Mode Helper Models & Widgets ─────────────────────

class _ParticipantEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int photoCount;

  const _ParticipantEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.photoCount,
  });
}

/// Non-clickable summary card for living mode (Photos / Participants)
class _LivingSummaryCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _LivingSummaryCard({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.smAlt),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            ),
            const SizedBox(height: Gaps.xxs),
            Text(
              '$count',
              style: AppText.headlineMedium.copyWith(
                color: BrandColors.living,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Participant tile for living mode — avatar + name + photo count
class _LivingParticipantTile extends StatelessWidget {
  final _ParticipantEntry entry;

  const _LivingParticipantTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Pads.ctlVXs,
        horizontal: Pads.sectionH,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: BrandColors.bg3,
            child: entry.userAvatar != null
                ? ClipOval(
                    child: Image.network(
                      entry.userAvatar!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: Gaps.sm),

          // Name
          Expanded(
            child: Text(
              entry.userName,
              style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Photo count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_outlined,
                size: IconSizes.sm,
                color: BrandColors.text2,
              ),
              const SizedBox(width: Gaps.xxs),
              Text(
                '${entry.photoCount}',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.living,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
      style: AppText.bodyMediumEmph
          .copyWith(color: BrandColors.text2, fontSize: 18),
    );
  }
}
