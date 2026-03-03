// lib/routes/app_router.dart
import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/authenticated_page.dart';
import '../features/auth/presentation/pages/login/login_page.dart';
import '../features/home/presentation/pages/home.dart';
import '../features/home/presentation/pages/home_search_page.dart';
import '../features/auth/presentation/pages/verify_otp.dart';
import '../features/auth/presentation/pages/login/login_otp_verification.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/finish_setup.dart';
import '../shared/layouts/main_layout.dart';
import '../features/create_event/presentation/pages/create_event_page.dart';
import '../features/create_event/presentation/pages/edit_event_page.dart';
import '../features/inbox/presentation/pages/inbox_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/other_profile_page.dart';
import '../features/event/presentation/pages/event_page.dart';
import '../features/event/presentation/pages/event_living_page.dart';
import '../features/event/presentation/pages/event_recap_page.dart';
import '../features/event/presentation/pages/manage_guests_page.dart';
import '../features/memory/presentation/pages/memory_page.dart';
import '../features/memory/presentation/pages/memory_viewer_page.dart';
import '../features/memory/presentation/pages/manage_memory_page.dart';
import '../features/memory/presentation/pages/photo_preview_page.dart';
import '../features/memory/presentation/pages/memory_ready_page.dart';
import '../features/memory/presentation/pages/share_memory_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/report_problem_page.dart';
import '../features/settings/presentation/pages/share_suggestion_page.dart';
import '../features/home/presentation/pages/events_list_page.dart';
import '../features/auth/presentation/pages/reviewer_auth_page.dart';
// share_memory_preview_page import removed - uses direct navigation

class AppRouter {
  static const String home = '/home';
  static const String homeSearch = '/home-search';
  static const String confirmedEventsList = '/confirmed-events-list';
  static const String pendingEventsList = '/pending-events-list';
  static const String auth = '/auth';
  static const String mainLayout = '/main';
  static const String createEvent = '/create-event';
  static const String editEvent = '/edit-event';
  static const String inbox = '/inbox';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String otherProfile = '/other-profile';
  static const String event = '/event';
  static const String eventLiving = '/event-living';
  static const String eventRecap = '/event-recap';
  static const String memory = '/memory';
  static const String memoryViewer = '/memory-viewer';
  static const String photoPreview = '/photo-preview';
  static const String manageMemory = '/manage-memory';
  static const String memoryReady = '/memory-ready';
  static const String shareMemory = '/share-memory';
  // shareMemoryPreview removed - uses direct Navigator.push with imageBytes
  static const String loginPage = '/login';
  static const String otpVerification = '/otp';
  static const String loginVerification = '/otp-login';
  static const String authHomepage = '/';
  static const String enterPhonePage = '/phone';
  static const String authenticationDone = '/auth-done';
  static const String finishSetup = '/finish-setup';
  static const String settings = '/settings';
  static const String reportProblem = '/report-problem';
  static const String shareSuggestion = '/share-suggestion';
  static const String manageGuests = '/manage-guests';
  static const String reviewerAuth = '/reviewer-auth';

  static final routes = <String, WidgetBuilder>{
    auth: (context) => const AuthPage(),
    reviewerAuth: (context) => const ReviewerAuthPage(),
    home: (context) => const HomePage(),
    homeSearch: (context) => const HomeSearchPage(),
    confirmedEventsList: (context) =>
        const EventsListPage(type: EventsListType.confirmed),
    pendingEventsList: (context) =>
        const EventsListPage(type: EventsListType.pending),
    mainLayout: (context) => const MainLayout(),
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
    profile: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ProfilePage(showBackButton: args?['showBackButton'] ?? false);
    },
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
    eventRecap: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return EventRecapPage(eventId: args?['eventId'] ?? 'event-1');
    },
    manageGuests: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ManageGuestsPage(eventId: args?['eventId'] ?? 'event-1');
    },
    memory: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MemoryPage(
        memoryId: args?['memoryId'] ?? 'memory-1',
        viewSource: args?['viewSource'] as String?,
      );
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
    // shareMemoryPreview removed - uses direct Navigator.push with imageBytes
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
    settings: (context) => const SettingsPage(),
    reportProblem: (context) => const ReportProblemPage(),
    shareSuggestion: (context) => const ShareSuggestionPage(),
  };
}
