// lib/routes/app_router.dart
import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/authenticated_page.dart';
import '../features/auth/presentation/pages/login/login_page.dart';
import '../features/home/presentation/pages/home.dart';
import '../features/auth/presentation/pages/verifyotp.dart';
import '../features/auth/presentation/pages/login/login_otp_verification.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/finish_setup.dart';
import '../shared/layouts/main_layout.dart';
import '../features/groups/presentation/pages/groups_page.dart';
import '../features/create_event/presentation/pages/create_event_page.dart';
import '../features/activities/presentation/pages/activities_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/edit_profile_page.dart';

class AppRouter {
  static const String home = '/home';
  static const String auth = '/auth';
  static const String mainLayout = '/main';
  static const String groups = '/groups';
  static const String createEvent = '/create-event';
  static const String activities = '/activities';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
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
    createEvent: (context) => const CreateEventPage(),
    activities: (context) => const ActivitiesPage(),
    profile: (context) => const ProfilePage(),
    editProfile: (context) => const EditProfilePage(),
    loginPage: (context) => const LoginPage(),

    loginVerification: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return LoginOtpVerificationPage(email: args['email']);
    },
    otpVerification: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return OtpVerificationPage(email: args['email']);
    },
    authenticationDone: (context) => const OnboardingSuccessPage(),
    finishSetup: (context) => const CreateProfilePage(),
  };
}
