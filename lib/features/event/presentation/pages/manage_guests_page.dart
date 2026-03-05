import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../routes/app_router.dart';
import '../../../../config/app_config.dart';
import '../../../../services/analytics_service.dart';
import '../../../../shared/components/common/invite_bottom_sheet.dart';
import '../../../event_invites/presentation/providers/event_invite_providers.dart';
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
  void initState() {
    super.initState();
    AnalyticsService.screenViewed('manage_guests', eventId: widget.eventId);
  }

  /// Refresh all guest and event data
  Future<void> _refreshData() async {
    ref.invalidate(eventRsvpsProvider(widget.eventId));
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(eventPhotosProvider(widget.eventId));
    ref.invalidate(guestRsvpListProvider(widget.eventId));
    // Wait for RSVPs to reload
    await ref.read(eventRsvpsProvider(widget.eventId).future);
  }

  /// Get accent color based on event status
  Color _getAccentColor(EventStatus? status) {
    switch (status) {
      case EventStatus.living:
        return BrandColors.living;
      case EventStatus.recap:
        return BrandColors.recap;
      case EventStatus.confirmed:
        return BrandColors.planning;
      default:
        return BrandColors.planning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rsvpsAsync = ref.watch(eventRsvpsProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final eventStatus = eventAsync.value?.status;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isPhotoMode = eventStatus == EventStatus.living ||
        eventStatus == EventStatus.recap ||
        eventStatus == EventStatus.ended;

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: isPhotoMode ? 'Guests' : 'Manage Guests',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.ios_share, color: BrandColors.text1),
          onPressed: () async {
            try {
              final useCase = ref.read(createEventInviteLinkProvider);
              final entity = await useCase(
                eventId: widget.eventId,
                shareChannel: 'manage_guests',
              );
              final inviteUrl = '${AppConfig.invitesBaseUrl}/i/${entity.token}';
              if (context.mounted) {
                InviteBottomSheet.show(
                  context: context,
                  inviteUrl: inviteUrl,
                  entityName: eventAsync.value?.name ?? 'this event',
                  entityType: 'event',
                  eventEmoji: eventAsync.value?.emoji ?? '📅',
                  eventId: widget.eventId,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to create invite link'),
                  ),
                );
              }
            }
          },
        ),
      ),
      body: rsvpsAsync.when(
        data: (rsvps) => RefreshIndicator(
          onRefresh: _refreshData,
          color: _getAccentColor(eventStatus),
          backgroundColor: BrandColors.bg2,
          child: isPhotoMode
              ? _buildPhotoContributorContent(
                  rsvps, eventStatus!, currentUserId)
              : _buildContent(rsvps),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: isPhotoMode ? BrandColors.living : BrandColors.planning,
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

  // ─── Photo Contributor Mode (Living / Recap / Ended) ────

  Widget _buildPhotoContributorContent(
      List<Rsvp> rsvps, EventStatus eventStatus, String? currentUserId) {
    final photosAsync = ref.watch(eventPhotosProvider(widget.eventId));
    final photos = photosAsync.value ?? [];

    // Fetch web guest RSVPs for merging
    final guestListAsync = ref.watch(guestRsvpListProvider(widget.eventId));
    final guestList = guestListAsync.valueOrNull ?? [];

    // Accent color based on status
    final accentColor = eventStatus == EventStatus.living
        ? BrandColors.living
        : eventStatus == EventStatus.recap
            ? BrandColors.recap
            : BrandColors.text1; // ended / memory

    // Build set of app user emails for deduplication
    final appUserEmails = <String>{};
    for (final rsvp in rsvps) {
      if (rsvp.userEmail != null && rsvp.userEmail!.isNotEmpty) {
        appUserEmails.add(rsvp.userEmail!.trim().toLowerCase());
      }
    }

    // Convert web guests to Rsvp entities, excluding duplicates by email
    final webGuestRsvps = <Rsvp>[];
    for (final g in guestList) {
      final guestEmail =
          (g['guest_phone'] as String?)?.trim().toLowerCase() ?? '';
      // Skip if this web guest's email matches an app user's email
      if (guestEmail.isNotEmpty && appUserEmails.contains(guestEmail)) {
        continue;
      }
      final rsvpStr = g['rsvp'] as String? ?? 'going';
      RsvpStatus status;
      switch (rsvpStr) {
        case 'going':
          status = RsvpStatus.going;
          break;
        case 'not_going':
          status = RsvpStatus.notGoing;
          break;
        case 'maybe':
          status = RsvpStatus.maybe;
          break;
        default:
          status = RsvpStatus.going;
      }
      webGuestRsvps.add(Rsvp(
        id: g['id'] as String? ?? '',
        eventId: widget.eventId,
        userId: '', // Web guests have no user account
        userName: g['guest_name'] as String? ?? 'Guest',
        userAvatar: null,
        status: status,
        createdAt: g['created_at'] != null
            ? DateTime.tryParse(g['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      ));
    }

    // Merge app + web guests (going only)
    final allGoingRsvps = [
      ...rsvps.where((r) => r.status == RsvpStatus.going),
      ...webGuestRsvps.where((r) => r.status == RsvpStatus.going),
    ];

    // Count total photos and participants
    final totalPhotos = photos.length;
    final participantCount = allGoingRsvps.length;

    // Build per-user photo counts from photos data
    final photoCountByUser = <String, int>{};
    for (final photo in photos) {
      final uploaderId = photo['uploader_id'] as String? ?? '';
      if (uploaderId.isNotEmpty) {
        photoCountByUser[uploaderId] = (photoCountByUser[uploaderId] ?? 0) + 1;
      }
    }

    // Build participant list — all going participants (0 photos shown as 'No photos yet')
    final participantEntries = allGoingRsvps
        .map((rsvp) => _ParticipantEntry(
              userId: rsvp.userId,
              userName: rsvp.userName,
              userAvatar: rsvp.userAvatar,
              photoCount: rsvp.userId.isNotEmpty
                  ? (photoCountByUser[rsvp.userId] ?? 0)
                  : 0, // Web guests can't upload photos
            ))
        .toList();

    // Sort by photo count descending, then alphabetically
    participantEntries.sort((a, b) {
      final countCmp = b.photoCount.compareTo(a.photoCount);
      if (countCmp != 0) return countCmp;
      return a.userName.compareTo(b.userName);
    });

    return Column(
      children: [
        // Summary cards: Participants + Photos
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.screenH,
            vertical: Gaps.md,
          ),
          child: Row(
            children: [
              _LivingSummaryCard(
                icon: Icons.people_outline,
                count: participantCount,
                label: 'Participants',
                accentColor: accentColor,
              ),
              const SizedBox(width: Gaps.xs),
              _LivingSummaryCard(
                icon: Icons.photo_library_outlined,
                count: totalPhotos,
                label: 'Photos',
                accentColor: accentColor,
              ),
            ],
          ),
        ),

        // Participant list with photo counts
        Expanded(
          child: participantEntries.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [_buildLivingEmptyState()],
                )
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
                        return _LivingParticipantTile(
                          entry: entry,
                          currentUserId: currentUserId,
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
    // Fetch web guest RSVPs
    final guestListAsync = ref.watch(guestRsvpListProvider(widget.eventId));
    final guestList = guestListAsync.valueOrNull ?? [];

    // Build set of app user emails for deduplication
    final appUserEmails = <String>{};
    for (final rsvp in rsvps) {
      if (rsvp.userEmail != null && rsvp.userEmail!.isNotEmpty) {
        appUserEmails.add(rsvp.userEmail!.trim().toLowerCase());
      }
    }

    // Convert web guests to Rsvp entities, excluding duplicates by email
    final webGuestRsvps = <Rsvp>[];
    for (final g in guestList) {
      final guestEmail =
          (g['guest_phone'] as String?)?.trim().toLowerCase() ?? '';
      // Skip if this web guest's email matches an app user's email
      if (guestEmail.isNotEmpty && appUserEmails.contains(guestEmail)) {
        continue;
      }
      final rsvpStr = g['rsvp'] as String? ?? 'going';
      RsvpStatus status;
      switch (rsvpStr) {
        case 'going':
          status = RsvpStatus.going;
          break;
        case 'not_going':
          status = RsvpStatus.notGoing;
          break;
        case 'maybe':
          status = RsvpStatus.maybe;
          break;
        default:
          status = RsvpStatus.going;
      }
      webGuestRsvps.add(Rsvp(
        id: g['id'] as String? ?? '',
        eventId: widget.eventId,
        userId: '', // Web guests have no user account
        userName: g['guest_name'] as String? ?? 'Guest',
        userAvatar: null,
        status: status,
        createdAt: g['created_at'] != null
            ? DateTime.tryParse(g['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      ));
    }

    // Merge app + web guests (deduplicated)
    final allRsvps = [...rsvps, ...webGuestRsvps];

    // Count votes by status (exclude pending)
    final goingCount =
        allRsvps.where((r) => r.status == RsvpStatus.going).length;
    final maybeCount =
        allRsvps.where((r) => r.status == RsvpStatus.maybe).length;
    final cantCount =
        allRsvps.where((r) => r.status == RsvpStatus.notGoing).length;

    // Filter rsvps based on selected status
    final filteredRsvps = _selectedFilter != null
        ? allRsvps.where((r) => r.status == _selectedFilter).toList()
        : allRsvps.where((r) => r.status != RsvpStatus.pending).toList();

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
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [_buildEmptyState()],
                )
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
                        final isWebGuest = rsvp.userId.isEmpty;
                        return GuestListTile(
                          rsvp: rsvp,
                          onTap: isWebGuest
                              ? null
                              : () {
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

/// Non-clickable summary card for living/recap/ended modes
class _LivingSummaryCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color accentColor;

  const _LivingSummaryCard({
    required this.icon,
    required this.count,
    required this.label,
    this.accentColor = BrandColors.living,
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
                color: accentColor,
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
  final String? currentUserId;

  const _LivingParticipantTile({
    required this.entry,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.userId == currentUserId;
    return GestureDetector(
      onTap: () {
        if (isCurrentUser) {
          Navigator.of(context).pushNamed(
            AppRouter.profile,
            arguments: {'showBackButton': true},
          );
        } else {
          Navigator.of(context).pushNamed(
            AppRouter.otherProfile,
            arguments: {'userId': entry.userId},
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                isCurrentUser ? 'You' : entry.userName,
                style:
                    AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Photo count: number (text2) + icon after
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.photoCount}',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text2,
                  ),
                ),
                const SizedBox(width: Gaps.xxs),
                const Icon(
                  Icons.photo_outlined,
                  size: IconSizes.sm,
                  color: BrandColors.text2,
                ),
              ],
            ),
          ],
        ),
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
