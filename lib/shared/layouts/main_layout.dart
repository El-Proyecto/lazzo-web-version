import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/nav/navigation_bar.dart' as nav;
import '../../features/groups/presentation/pages/groups_page.dart';
import '../../features/create_event/presentation/pages/create_event_page.dart';
import '../../features/activities/presentation/pages/activities_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/home.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(), // 0 - Home
    const GroupsPage(), // 1 - Groups
    const CreateEventPage(), // 2 - Create Event / Camera (center button)
    const ActivitiesPage(), // 3 - Activities
    const ProfilePage(), // 4 - Profile
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: nav.NavigationBar(
        state: nav.NavBarState.normal,
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
