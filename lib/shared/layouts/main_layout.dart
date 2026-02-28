import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analytics_service.dart';
import '../components/nav/navigation_bar.dart' as nav;
import '../components/common/top_banner.dart';
import '../components/dialogs/add_photo_bottom_sheet.dart';
import '../components/inputs/photo_selector.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/inbox/presentation/pages/inbox_page.dart';
import '../../features/inbox/presentation/providers/notifications_provider.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/home.dart';
import '../../features/home/presentation/providers/home_event_providers.dart';
import '../../features/home/domain/entities/home_event.dart';
import '../../features/event/presentation/providers/event_providers.dart';
import '../../features/event/presentation/providers/event_photo_providers.dart';
import '../../routes/app_router.dart';
import '../../services/event_status_service.dart';
import 'main_layout_providers.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0; // Começar na aba Home
  bool _hasShownBanner = false; // Track if banner was already shown
  bool _hasCheckedMemoryReady = false; // Track if memory ready check was done

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check for success banner arguments - only show once
    if (!_hasShownBanner) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['showSuccessBanner'] == true) {
        final eventName = args['eventName'] ?? '';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          TopBanner.showSuccess(
            context,
            message: '$eventName created successfully!',
          );
        });

        // Mark banner as shown and clear the argument to prevent re-showing
        _hasShownBanner = true;
        args['showSuccessBanner'] = false;
      }
    }
  }

  final List<Widget> _pages = [
    const HomePage(), // 0 - Home
    const CalendarPage(), // 1 - Calendar
    const InboxPage(), // 2 - Inbox
    const ProfilePage(), // 3 - Profile
  ];

  void _onNavTap(int index) async {
    if (index == 2) {
      // Center button - action depends on NavBar state
      final nextEventStatus = ref.read(navBarStateProvider);

      if (nextEventStatus == HomeEventStatus.living) {
        // Living mode: Check if there are multiple living events
        final livingEventsAsync = await ref.read(
          livingAndRecapEventsControllerProvider.future,
        );
        final livingEvents = livingEventsAsync
            .where(
              (e) => e.status == HomeEventStatus.living,
            )
            .toList();

        if (livingEvents.isEmpty) {
          if (mounted) {
            TopBanner.showError(
              context,
              message: 'No event in living mode found',
            );
          }
          return;
        }

        if (livingEvents.length > 1) {
          // Multiple events - show event selection bottom sheet (Phase 1)
          if (mounted) {
            final selectedEvent = await AddPhotoEventSelectorSheet.show(
              context: context,
              title: 'Add Photo',
              events: livingEvents
                  .map((e) => PhotoEventOption(
                        id: e.id,
                        name: e.name,
                        emoji: e.emoji,
                      ))
                  .toList(),
            );
            if (selectedEvent != null && mounted) {
              // Phase 2: Show camera/gallery options
              _showLivingPhotoOptions(selectedEvent.id);
            }
          }
          return;
        }

        // Single event - show camera/gallery options directly
        _showLivingPhotoOptions(livingEvents.first.id);
      } else if (nextEventStatus == HomeEventStatus.recap) {
        // Recap mode: Check if there are multiple recap events
        final recapEventsAsync = await ref.read(
          livingAndRecapEventsControllerProvider.future,
        );
        final recapEvents = recapEventsAsync
            .where(
              (e) => e.status == HomeEventStatus.recap,
            )
            .toList();

        if (recapEvents.isEmpty) {
          if (mounted) {
            TopBanner.showError(
              context,
              message: 'No event in recap mode found',
            );
          }
          return;
        }

        if (recapEvents.length > 1) {
          // Multiple events - show event selection bottom sheet (Phase 1)
          if (mounted) {
            final selectedEvent = await AddPhotoEventSelectorSheet.show(
              context: context,
              title: 'Add Photos',
              events: recapEvents
                  .map((e) => PhotoEventOption(
                        id: e.id,
                        name: e.name,
                        emoji: e.emoji,
                      ))
                  .toList(),
            );
            if (selectedEvent != null && mounted) {
              _handleRecapEventPhotos(selectedEvent.id);
            }
          }
          return;
        }

        // Single event - proceed directly
        _handleRecapEventPhotos(recapEvents.first.id);
      } else {
        // Planning state: navigate to Create Event page
        Navigator.pushNamed(context, AppRouter.createEvent);
      }
      return;
    }

    // Map navigation bar indices to page indices
    // NavBar: 0=Home, 1=Calendar, 2=Center(handled above), 3=Inbox, 4=Profile
    // Pages: 0=Home, 1=Calendar, 2=Inbox, 3=Profile
    int pageIndex;
    switch (index) {
      case 0: // Home
        pageIndex = 0;
        break;
      case 1: // Calendar
        pageIndex = 1;
        break;
      case 3: // Inbox
        pageIndex = 2;
        break;
      case 4: // Profile
        pageIndex = 3;
        break;
      default:
        return;
    }

    // If tapping the same tab, scroll to top and refresh
    if (pageIndex == _currentIndex) {
      // Notify the page to scroll to top via scrollToTopProvider
      ref.read(scrollToTopProvider.notifier).state++;
      return; // Don't change state if already on this page
    }

    setState(() {
      _currentIndex = pageIndex;
    });

    // Screen tracking removed from tab navigation.
    // calendar → tracked on interaction (CalendarPage).
    // actions  → tracked when Actions tab is selected (InboxPage).

    // Update provider as well
    ref.read(mainLayoutTabProvider.notifier).state = pageIndex;
  }

  /// Show photo options bottom sheet (camera/gallery) for living event
  void _showLivingPhotoOptions(String eventId) {
    PhotoSelectionBottomSheet.show(
      context: context,
      title: 'Add Photo',
      showRemoveOption: false,
      onAction: (action) async {
        if (action == PhotoSourceAction.camera) {
          await _handleLivingEventPhoto(eventId);
        } else if (action == PhotoSourceAction.gallery) {
          await _handleLivingEventGallery(eventId);
        }
      },
    );
  }

  /// Handle photo capture for living event (camera)
  Future<void> _handleLivingEventPhoto(String eventId) async {
    try {
      // Get photo upload notifier
      final photoNotifier = ref.read(
        eventPhotoUploadNotifierProvider(eventId).notifier,
      );

      // Take photo and upload
      await photoNotifier.takePhoto(
        eventId: eventId,
      );

      // Show result
      final uploadState = ref.read(
        eventPhotoUploadNotifierProvider(eventId),
      );

      uploadState.when(
        data: (photoUrl) {
          if (photoUrl != null && mounted) {
            TopBanner.showSuccess(
              context,
              message: 'Photo uploaded successfully!',
            );

            // Optimistic UI: invalidate all photo-related providers
            ref.invalidate(eventDetailProvider(eventId));
            ref.invalidate(eventPhotosProvider(eventId));

            // Navigate to manage memory page
            Navigator.pushNamed(
              context,
              AppRouter.manageMemory,
              arguments: {
                'memoryId': eventId,
              },
            );
          }
        },
        loading: () {},
        error: (error, _) {
          if (mounted) {
            TopBanner.showError(
              context,
              message: '❌ Failed to upload photo: $error',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'Error: $e',
        );
      }
    }
  }

  /// Handle gallery pick for living event
  Future<void> _handleLivingEventGallery(String eventId) async {
    try {
      final photoNotifier = ref.read(
        eventPhotoUploadNotifierProvider(eventId).notifier,
      );

      await photoNotifier.pickPhotoFromGallery(eventId: eventId);

      final uploadState = ref.read(
        eventPhotoUploadNotifierProvider(eventId),
      );

      uploadState.when(
        data: (photoUrl) {
          if (photoUrl != null && mounted) {
            TopBanner.showSuccess(
              context,
              message: 'Photo uploaded successfully!',
            );
            ref.invalidate(eventDetailProvider(eventId));
            ref.invalidate(eventPhotosProvider(eventId));

            Navigator.pushNamed(
              context,
              AppRouter.manageMemory,
              arguments: {'memoryId': eventId},
            );
          }
        },
        loading: () {},
        error: (error, _) {
          if (mounted) {
            TopBanner.showError(
              context,
              message: '❌ Failed to upload photo: $error',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        TopBanner.showError(context, message: 'Error: $e');
      }
    }
  }

  /// Handle photo selection for recap event
  Future<void> _handleRecapEventPhotos(String eventId) async {
    try {
      // First, update event statuses to ensure recap events are correctly marked
      try {
        final statusService = EventStatusService(Supabase.instance.client);
        final result = await statusService.updateEventStatuses();
        if (result.updatedCount > 0) {
          // Refresh next event provider to get updated status
          ref.invalidate(nextEventControllerProvider);
        }
        // If any events transitioned from recap→ended, show memory ready
        if (result.recapEndedEventIds.isNotEmpty && mounted) {
          Navigator.of(context).pushNamed(
            AppRouter.memoryReady,
            arguments: {'memoryId': result.recapEndedEventIds.first},
          );
          return;
        }
      } catch (e) {
        // Failed to update event status - will retry on next load
      }

      // Recap mode: Always open gallery to upload photos
      AnalyticsService.track('photo_upload_started', properties: {
        'event_id': eventId,
        'source': 'gallery',
        'platform': 'ios',
      });
      final picker = ImagePicker();
      final selectedImages = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (selectedImages.isNotEmpty && mounted) {
        // Limit to 5 photos
        final limitedImages = selectedImages.take(5).toList();

        if (limitedImages.length < selectedImages.length) {
          TopBanner.showInfo(
            context,
            message: 'Maximum 5 photos selected',
          );
        }

        // Navigate to ManageMemoryPage with selected photos
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRouter.manageMemory,
            arguments: {
              'memoryId': eventId,
              'selectedPhotos': limitedImages.map((img) => img.path).toList(),
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'Error: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for pending memory ready notifications on app open (once only)
    if (!_hasCheckedMemoryReady) {
      final pendingMemoryReady = ref.watch(pendingMemoryReadyProvider);
      pendingMemoryReady.whenData((eventId) {
        if (eventId != null && !_hasCheckedMemoryReady && mounted) {
          _hasCheckedMemoryReady = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushNamed(
                AppRouter.memoryReady,
                arguments: {'memoryId': eventId},
              );
            }
          });
        }
      });
    }

    // Listen to tab changes from provider
    ref.listen<int>(mainLayoutTabProvider, (previous, next) {
      if (next != _currentIndex && mounted) {
        setState(() {
          _currentIndex = next;
        });
      }
    });

    // Map page index back to navigation bar index
    // NavBar: 0=Home, 1=Calendar, 2=Center, 3=Inbox, 4=Profile
    int navBarIndex;
    switch (_currentIndex) {
      case 0: // Home page -> nav index 0
        navBarIndex = 0;
        break;
      case 1: // Calendar page -> nav index 1
        navBarIndex = 1;
        break;
      case 2: // Inbox page -> nav index 3
        navBarIndex = 3;
        break;
      case 3: // Profile page -> nav index 4
        navBarIndex = 4;
        break;
      default:
        navBarIndex = 0;
    }

    // Get NavBar state from next event status
    final nextEventStatus = ref.watch(navBarStateProvider);

    // Get unread notification count
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    // Map event status to NavBar state
    // Pending events also show Planning (green button with +)
    nav.NavBarState navBarState;
    if (nextEventStatus == HomeEventStatus.living) {
      navBarState = nav.NavBarState.living;
    } else if (nextEventStatus == HomeEventStatus.recap) {
      navBarState = nav.NavBarState.recap;
    } else {
      // Default to planning for pending/confirmed/null
      navBarState = nav.NavBarState.planning;
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: nav.NavigationBar(
        state: navBarState,
        currentIndex: navBarIndex,
        onTap: _onNavTap,
        unreadNotificationCount: unreadCount,
      ),
    );
  }
}
