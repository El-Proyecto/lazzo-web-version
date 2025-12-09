import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/nav/navigation_bar.dart' as nav;
import '../components/common/top_banner.dart';
import '../../features/groups/presentation/pages/groups_page.dart';
import '../../features/inbox/presentation/pages/inbox_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/home.dart';
import '../../features/home/presentation/providers/home_event_providers.dart';
import '../../features/home/domain/entities/home_event.dart';
import '../../features/memory/presentation/providers/memory_providers.dart';
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
    const GroupsPage(), // 1 - Groups
    const InboxPage(), // 2 - Inbox (moved from index 3)
    const ProfilePage(), // 3 - Profile (moved from index 4)
  ];

  void _onNavTap(int index) async {
    if (index == 2) {
      // Center button - action depends on NavBar state
      final nextEventStatus = ref.read(navBarStateProvider);

      if (nextEventStatus == HomeEventStatus.living) {
        // Living mode: open camera (TODO: implement)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Camera for living mode coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (nextEventStatus == HomeEventStatus.recap) {
        // First, update event statuses to ensure recap events are correctly marked
        try {
          final statusService = EventStatusService(Supabase.instance.client);
          final updatedCount = await statusService.updateEventStatuses();
          if (updatedCount > 0) {
            // Refresh next event provider to get updated status
            ref.invalidate(nextEventControllerProvider);
          }
        } catch (e) {
          // Failed to update event status - will retry on next load
        }

        // Recap mode: Get memoryId from next event (event in recap = memory)
        final nextEvent = await ref.read(nextEventControllerProvider.future);

        if (nextEvent == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No event in recap mode found'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        final memoryId = nextEvent.id; // eventId = memoryId for recap events

        // Get memory to check if user has already uploaded photos
        final memoryAsync =
            await ref.read(memoryDetailProvider(memoryId).future);
        final hasPhotos = memoryAsync != null && memoryAsync.photos.isNotEmpty;

        if (hasPhotos && mounted) {
          // User already has photos → go directly to manage memory page
          Navigator.pushNamed(
            context,
            AppRouter.manageMemory,
            arguments: {'memoryId': memoryId},
          );
        } else {
          // No photos yet → open gallery to upload photos
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 5 photos selected'),
                  duration: Duration(seconds: 2),
                ),
              );
            }

            // Navigate to ManageMemoryPage with selected photos
            if (mounted) {
              Navigator.pushNamed(
                context,
                AppRouter.manageMemory,
                arguments: {
                  'memoryId': memoryId,
                  'selectedPhotos':
                      limitedImages.map((img) => img.path).toList(),
                },
              );
            }
          }
        }
      } else {
        // Planning state: navigate to Create Event page
        Navigator.pushNamed(context, AppRouter.createEvent);
      }
      return;
    }

    // Map navigation bar indices to page indices
    // NavBar: 0=Home, 1=Groups, 2=Create(skip), 3=Inbox, 4=Profile
    // Pages: 0=Home, 1=Groups, 2=Inbox, 3=Profile
    int pageIndex;
    switch (index) {
      case 0: // Home
        pageIndex = 0;
        break;
      case 1: // Groups
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

    // Update provider as well
    ref.read(mainLayoutTabProvider.notifier).state = pageIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to tab changes from provider
    ref.listen<int>(mainLayoutTabProvider, (previous, next) {
      if (next != _currentIndex && mounted) {
        setState(() {
          _currentIndex = next;
        });
      }
    });

    // Map page index back to navigation bar index
    int navBarIndex;
    switch (_currentIndex) {
      case 0: // Home page -> nav index 0
        navBarIndex = 0;
        break;
      case 1: // Groups page -> nav index 1
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
      ),
    );
  }
}
