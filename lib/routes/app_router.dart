// lib/routes/app_router.dart
import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/authenticated_page.dart';
import '../features/auth/presentation/pages/login/login_page.dart';
import '../features/home/presentation/pages/home.dart';
import '../features/auth/presentation/pages/verify_otp.dart';
import '../features/auth/presentation/pages/login/login_otp_verification.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/finish_setup.dart';
import '../shared/layouts/main_layout.dart';
import '../features/groups/presentation/pages/groups_page.dart';
import '../features/groups/presentation/pages/create_group_page.dart';
import '../features/groups/presentation/pages/group_created_page.dart';
import '../features/create_event/presentation/pages/create_event_page.dart';
import '../features/create_event/presentation/pages/edit_event_page.dart';
import '../features/inbox/presentation/pages/inbox_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/other_profile_page.dart';
import '../features/event/presentation/pages/event_page.dart';
import '../features/event/presentation/pages/event_living_page.dart';
import '../features/event/presentation/pages/event_chat_page.dart';
import '../features/group_hub/presentation/pages/group_hub_page.dart';
import '../features/group_hub/presentation/pages/group_details_page.dart';
import '../features/memory/presentation/pages/memory_page.dart';
import '../features/memory/presentation/pages/memory_viewer_page.dart';
import '../features/memory/presentation/pages/manage_memory_page.dart';
import '../features/memory/presentation/pages/photo_preview_page.dart';
import '../features/memory/presentation/pages/memory_ready_page.dart';
import '../features/memory/presentation/pages/share_memory_page.dart';
import '../features/memory/presentation/pages/share_memory_preview_page.dart';

class AppRouter {
  static const String home = '/home';
  static const String auth = '/auth';
  static const String mainLayout = '/main';
  static const String groups = '/groups';
  static const String createGroup = '/create-group';
  static const String groupCreated = '/group-created';
  static const String createEvent = '/create-event';
  static const String editEvent = '/edit-event';
  static const String inbox = '/inbox';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String otherProfile = '/other-profile';
  static const String event = '/event';
  static const String eventLiving = '/event-living';
  static const String eventChat = '/event-chat';
  static const String groupHub = '/group-hub';
  static const String groupDetails = '/group-details';
  static const String memory = '/memory';
  static const String memoryViewer = '/memory-viewer';
  static const String photoPreview = '/photo-preview';
  static const String manageMemory = '/manage-memory';
  static const String memoryReady = '/memory-ready';
  static const String shareMemory = '/share-memory';
  static const String shareMemoryPreview = '/share-memory-preview';
  static const String loginPage = '/login';
  static const String otpVerification = '/otp';
  static const String loginVerification = '/otp-login';
  static const String authHomepage = '/';
  static const String enterPhonePage = '/phone';
  static const String authenticationDone = '/auth-done';
  static const String finishSetup = '/finish-setup';

  static final routes = <String, WidgetBuilder>{
    auth: (context) => const AuthPage(),
    home: (context) => const HomePage(),
    mainLayout: (context) => const MainLayout(),
    groups: (context) => const GroupsPage(),
    createGroup: (context) => const CreateGroupPage(),
    groupCreated: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return GroupCreatedPage(group: args['group']);
    },
    createEvent: (context) => const CreateEventPage(),
    editEvent: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final event = args?['event'];
      if (event == null) {
        // Return to previous screen if no event provided
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop();
        });
        return const Material(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return EditEventPage(event: event);
    },
    inbox: (context) => const InboxPage(),
    profile: (context) => const ProfilePage(),
    editProfile: (context) => const EditProfilePage(),
    otherProfile: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return OtherProfilePage(userId: args?['userId'] ?? 'user-1');
    },
    event: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return EventPage(eventId: args?['eventId'] ?? 'event-1');
    },
    eventLiving: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return EventLivingPage(eventId: args?['eventId'] ?? 'event-1');
    },
    eventChat: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return EventChatPage(eventId: args?['eventId'] ?? 'event-1');
    },
    groupHub: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return GroupHubPage(
        groupId: args?['groupId'] ?? 'group-1',
        groupName: args?['groupName'] ?? 'Group Name',
        groupPhotoUrl: args?['groupPhotoUrl'],
        memberCount: args?['memberCount'] ?? 3,
      );
    },
    groupDetails: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return GroupDetailsPage(
        groupId: args?['groupId'] ?? 'group-1',
      );
    },
    memory: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MemoryPage(memoryId: args?['memoryId'] ?? 'memory-1');
    },
    memoryViewer: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MemoryViewerPage(
        memoryId: args?['memoryId'] ?? 'memory-1',
        initialPhotoId: args?['photoId'],
      );
    },
    photoPreview: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PhotoPreviewPage(
        memoryId: args?['memoryId'] ?? 'memory-1',
        initialPhotoId: args?['photoId'],
      );
    },
    manageMemory: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ManageMemoryPage(
        memoryId: args?['memoryId'] ?? 'memory-1',
      );
    },
    memoryReady: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MemoryReadyPage(
        memoryId: args?['memoryId'] ?? 'memory-1',
      );
    },
    shareMemory: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ShareMemoryPage(
        memoryId: args?['memoryId'] ?? 'memory-1',
      );
    },
    shareMemoryPreview: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ShareMemoryPreviewPage(
        memoryId: args?['memoryId'] ?? 'memory-1',
      );
    },
    loginPage: (context) => const LoginPage(),
    loginVerification: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return LoginOtpVerificationPage(email: args['email']);
    },
    otpVerification: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return OtpVerificationPage(
        email: args['email'],
        name: args['name'], // Optional name parameter
      );
    },
    authenticationDone: (context) => const OnboardingSuccessPage(),
    finishSetup: (context) => const CreateProfilePage(),
  };
}
