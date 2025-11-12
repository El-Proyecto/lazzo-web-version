import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/nav/navigation_bar.dart' as nav;
import '../../features/groups/presentation/pages/groups_page.dart';
import '../../features/inbox/presentation/pages/inbox_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/home.dart';
import '../../features/home/presentation/providers/banner_provider.dart';
import '../../routes/app_router.dart';
import 'main_layout_providers.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0; // Começar na aba Home

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check for success banner arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['showSuccessBanner'] == true) {
      // Set banner state via provider
      final eventName = args['eventName'] ?? '';
      final groupName = args['groupName'] ?? '';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(bannerProvider.notifier)
            .showSuccessBanner(eventName, groupName);
      });
    }
  }

  final List<Widget> _pages = [
    const HomePage(), // 0 - Home
    const GroupsPage(), // 1 - Groups
    const InboxPage(), // 2 - Inbox (moved from index 3)
    const ProfilePage(), // 3 - Profile (moved from index 4)
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      // Center button - navigate to Create Event page
      Navigator.pushNamed(context, AppRouter.createEvent);
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

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: nav.NavigationBar(
        state: nav.NavBarState.normal,
        currentIndex: navBarIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
