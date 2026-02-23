import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/components/sections/event_header.dart';
import '../../../../shared/components/inputs/photo_selector.dart';
import '../../../../shared/components/widgets/location_widget.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../providers/event_providers.dart';
import '../providers/event_photo_providers.dart';
import '../../../memory/presentation/providers/memory_providers.dart';
import '../widgets/recap_time_left_pill.dart';
import '../widgets/recap_action_row.dart';
import '../widgets/living_photos_widget.dart';
import '../widgets/recap_host_time_controls.dart';

/// Event page for Recap mode
/// Similar to Living page but with orange accent, End Now only (no add time),
/// and action buttons: Share, Upload (orange), Memory
class EventRecapPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventRecapPage({super.key, required this.eventId});

  @override
  ConsumerState<EventRecapPage> createState() => _EventRecapPageState();
}

class _EventRecapPageState extends ConsumerState<EventRecapPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitleInAppBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
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

  /// Show photo source selector (camera / gallery) and upload
  void _showPhotoSelector() {
    PhotoSelectionBottomSheet.show(
      context: context,
      title: 'Upload Photo',
      showRemoveOption: false,
      onAction: (action) async {
        final photoNotifier = ref.read(
          eventPhotoUploadNotifierProvider(widget.eventId).notifier,
        );

        if (action == PhotoSourceAction.camera) {
          await photoNotifier.takePhoto(eventId: widget.eventId);
        } else if (action == PhotoSourceAction.gallery) {
          await photoNotifier.pickPhotoFromGallery(eventId: widget.eventId);
        }

        _handlePhotoUploadResult();
      },
    );
  }

  /// Handle result after photo upload attempt
  void _handlePhotoUploadResult() {
    final uploadState = ref.read(
      eventPhotoUploadNotifierProvider(widget.eventId),
    );
    uploadState.when(
      data: (photoUrl) {
        if (photoUrl != null) {
          if (context.mounted) {
            TopBanner.showSuccess(context,
                message: 'Photo uploaded successfully!');
          }
          ref.invalidate(eventDetailProvider(widget.eventId));
          ref.invalidate(eventPhotosProvider(widget.eventId));
        }
      },
      loading: () {},
      error: (error, _) {
        if (context.mounted) {
          TopBanner.showError(context,
              message: 'Failed to upload photo: $error');
        }
      },
    );
  }

  /// Close recap phase (host only)
  Future<void> _handleCloseRecap() async {
    try {
      await ref.read(closeRecapUseCaseProvider).call(widget.eventId);
      ref.invalidate(eventDetailProvider(widget.eventId));
      if (context.mounted) {
        TopBanner.showSuccess(context, message: 'Recap ended successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        TopBanner.showError(context, message: 'Failed to end recap: $e');
      }
    }
  }

  /// Calculate recap end time (24h after event end)
  DateTime? _getRecapEndTime(DateTime? endDateTime) {
    if (endDateTime == null) return null;
    return endDateTime.add(const Duration(hours: 24));
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
        trailing: IconButton(
          icon: const Icon(Icons.people, color: BrandColors.text1),
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.manageGuests,
            arguments: {'eventId': widget.eventId},
          ),
        ),
      ),
      body: eventAsync.when(
        data: (event) {
          final recapEndTime = _getRecapEndTime(event.endDateTime);

          return RefreshIndicator(
            onRefresh: refreshEventData,
            color: BrandColors.recap,
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

                  // Time left pill (orange) with End Now for host
                  if (recapEndTime != null)
                    event.hostId == currentUserId
                        ? RecapHostTimeControls(
                            recapEndTime: recapEndTime,
                            onEndNow: _handleCloseRecap,
                          )
                        : RecapTimeLeftPill(
                            recapEndTime: recapEndTime,
                          ),
                  const SizedBox(height: Gaps.lg),

                  // Action row: Share, Upload (orange), Memory
                  RecapActionRow(
                    onShare: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'Check out ${event.name} on Lazzo! \uD83C\uDF89',
                        ),
                      );
                    },
                    onUpload: _showPhotoSelector,
                    onMemory: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.memory,
                        arguments: {'memoryId': widget.eventId},
                      );
                    },
                  ),
                  const SizedBox(height: Gaps.lg),

                  // Photos grid (reuses LivingPhotosWidget)
                  LivingPhotosWidget(
                    eventId: widget.eventId,
                    onTakePhoto: _showPhotoSelector,
                    onViewAll: () async {
                      final hasChanges = await Navigator.of(context).pushNamed(
                        AppRouter.manageMemory,
                        arguments: {
                          'memoryId': widget.eventId,
                        },
                      ) as bool?;
                      if (hasChanges == true) {
                        ref.invalidate(eventDetailProvider(widget.eventId));
                        ref.invalidate(eventPhotosProvider(widget.eventId));
                      }
                    },
                  ),
                  const SizedBox(height: Gaps.lg),

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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading event: $error')),
      ),
    );
  }
}
