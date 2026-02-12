import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/event_providers.dart';
import '../providers/event_photo_providers.dart';
import '../widgets/living_time_left_pill.dart';
import '../widgets/living_action_row.dart';
import '../widgets/host_time_controls.dart';

/// Event page for Living mode
/// Displays event in progress with photo upload and host controls
class EventLivingPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventLivingPage({super.key, required this.eventId});

  @override
  ConsumerState<EventLivingPage> createState() => _EventLivingPageState();
}

class _EventLivingPageState extends ConsumerState<EventLivingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInAppBar = false;

  @override
  void initState() {
    super.initState();
    // Listen to scroll to show/hide title in app bar
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show title when scrolled past ~150px (approximate header height)
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 150;
    if (shouldShow != _showTitleInAppBar) {
      setState(() {
        _showTitleInAppBar = shouldShow;
      });
    }
  }

  Future<void> refreshEventData() async {
    ref.invalidate(eventDetailProvider(widget.eventId));
    ref.invalidate(eventParticipantsProvider(widget.eventId));
    ref.invalidate(eventPhotosProvider(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: _showTitleInAppBar ? (eventAsync.value?.name ?? '') : '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: eventAsync.when(
        data: (event) => RefreshIndicator(
          onRefresh: refreshEventData,
          color: BrandColors.living,
          backgroundColor: BrandColors.bg2,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.screenH,
              vertical: Gaps.lg,
            ),
            child: Column(
              children: [
                // Event header
                EventHeader(
                  emoji: event.emoji,
                  title: event.name,
                  location: event.location?.displayName,
                  dateTime: event.startDateTime,
                  endDateTime: event.endDateTime,
                ),
                const SizedBox(height: Gaps.md),

                // Time left pill (with controls for host)
                if (event.endDateTime != null)
                  event.hostId == currentUserId
                      ? HostTimeControls(
                          eventEndTime: event.endDateTime!,
                          onExtend30Minutes: () async {
                            // Extend event by 30 minutes
                            try {
                              await ref
                                  .read(extendEventTimeProvider)
                                  .call(widget.eventId, 30);
                              // Refresh event details
                              ref.invalidate(
                                  eventDetailProvider(widget.eventId));
                              if (context.mounted) {
                                TopBanner.showSuccess(context,
                                    message: 'Event extended by 30 minutes');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TopBanner.showError(context,
                                    message: 'Failed to extend event: $e');
                              }
                            }
                          },
                          onCustomExtend: (minutes) async {
                            // Extend event by custom minutes
                            try {
                              await ref
                                  .read(extendEventTimeProvider)
                                  .call(widget.eventId, minutes);
                              // Refresh event details
                              ref.invalidate(
                                  eventDetailProvider(widget.eventId));
                              if (context.mounted) {
                                TopBanner.showSuccess(context,
                                    message:
                                        'Event extended by $minutes minutes');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TopBanner.showError(context,
                                    message: 'Failed to extend event: $e');
                              }
                            }
                          },
                          onEndNow: () async {
                            // End event immediately
                            try {
                              await ref
                                  .read(endEventNowProvider)
                                  .call(widget.eventId);
                              // Refresh event details
                              ref.invalidate(
                                  eventDetailProvider(widget.eventId));
                              if (context.mounted) {
                                TopBanner.showSuccess(context,
                                    message: 'Event ended successfully');
                                // Navigate back to group hub or home
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TopBanner.showError(context,
                                    message: 'Failed to end event: $e');
                              }
                            }
                          },
                        )
                      : LivingTimeLeftPill(
                          eventEndTime: event.endDateTime!,
                        ),
                const SizedBox(height: Gaps.lg),

                // Action row
                LivingActionRow(
                  onTakePhoto: () async {
                    // Get photo upload notifier
                    final photoNotifier = ref.read(
                      eventPhotoUploadNotifierProvider(widget.eventId).notifier,
                    );

                    // Take photo and upload
                    await photoNotifier.takePhoto(
                      eventId: widget.eventId,
                    );

                    // Show result
                    final uploadState = ref.read(
                      eventPhotoUploadNotifierProvider(widget.eventId),
                    );

                    uploadState.when(
                      data: (photoUrl) {
                        if (photoUrl != null) {
                          TopBanner.showSuccess(
                            context,
                            message: '✅ Photo uploaded successfully!',
                          );

                          // Optimistic UI: invalidate all photo-related providers
                          // This forces fresh data fetch when navigating to manage memory
                          ref.invalidate(eventDetailProvider(widget.eventId));
                          ref.invalidate(eventPhotosProvider(widget.eventId));

                          // Navigate immediately to manage memory page
                          // The manageMemoryProvider will fetch fresh photos on init
                          if (context.mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRouter.manageMemory,
                              arguments: {
                                'memoryId': widget.eventId,
                              },
                            );
                          }
                        }
                      },
                      loading: () {},
                      error: (error, _) {
                        TopBanner.showError(
                          context,
                          message: '❌ Failed to upload photo: $error',
                        );
                      },
                    );
                  },
                  onViewMemory: () async {
                    // Navigate to manage memory page and refresh on return if changes made
                    final hasChanges = await Navigator.pushNamed<bool>(
                      context,
                      AppRouter.manageMemory,
                      arguments: {
                        'memoryId': widget.eventId,
                      },
                    );

                    // Refresh data if changes were made
                    if (hasChanges == true) {
                      ref.invalidate(eventDetailProvider(widget.eventId));
                      ref.invalidate(eventPhotosProvider(widget.eventId));
                    }
                  },
                ),
                const SizedBox(height: Gaps.lg),

                // LAZZO 2.0: Expenses widget removed

                // Location Widget (if location is set)
                if (event.location != null)
                  LocationWidget(
                    displayName: event.location!.displayName,
                    formattedAddress: event.location!.formattedAddress,
                    latitude: event.location!.latitude,
                    longitude: event.location!.longitude,
                  ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading event: $error')),
      ),
    );
  }
}
