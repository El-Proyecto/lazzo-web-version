// lib/routes/app_router.dart
import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/authenticated_page.dart';
import '../features/auth/presentation/pages/login/login_page.dart';
import '../features/home/presentation/pages/home.dart';
import '../features/auth/presentation/pages/verifyOTP.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/enter_phone_page.dart';
import '../features/auth/presentation/pages/finish_setup.dart';

class AppRouter {
  static const String home = '/home';
  static const String auth = '/auth';
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
    loginPage: (context) => const LoginPage(),
    //loginVerification: (context) {
    //  final args =
    //      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    //  return LoginVerificationPage(phoneNumber: args['phoneNumber']);
    //},
    otpVerification: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return OtpVerificationPage(email: args['email']);
    },
    enterPhonePage: (context) => EnterPhonePage(),
    authenticationDone: (context) => OnboardingSuccessPage(),
    finishSetup: (context) => CreateProfilePage(),
  };
}
