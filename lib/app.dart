// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:lazzo/routes/app_router.dart';
import 'package:lazzo/shared/themes/app_theme.dart';
import 'package:lazzo/features/auth/presentation/providers/auth_provider.dart';
import 'package:lazzo/shared/components/loading/app_loading_screen.dart';
import 'package:lazzo/features/home/presentation/providers/home_event_providers.dart';
import 'package:lazzo/features/groups/presentation/providers/groups_provider.dart';
import 'package:lazzo/features/group_invites/presentation/providers/accept_group_invites_providers.dart';
import 'package:lazzo/services/push_notification_initializer.dart';
import 'package:lazzo/services/pending_invite_service.dart';

class LazzoApp extends ConsumerStatefulWidget {
  const LazzoApp({super.key});

  @override
  ConsumerState<LazzoApp> createState() => _LazzoAppState();
}

class _LazzoAppState extends ConsumerState<LazzoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _uriLinkSub;

  /// Pending invite token to process after login
  String? _pendingInviteToken;

  @override
  Widget build(BuildContext context) {
    // Initialize push notifications (watches auth state automatically)
    ref.watch(pushNotificationInitializerProvider);

    return MaterialApp(
      title: 'Lazzo',
      navigatorKey: _navigatorKey,
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
      routes: AppRouter.routes,
      // onGenerateRoute: ... (se precisares mais tarde)
    );
  }

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    // Handle initial link (cold start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialLink();
    });

    // Listen to incoming links (warm start)
    _uriLinkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (error) {
        // Silently handle errors - don't crash the app
      },
    );
  }

  @override
  void dispose() {
    _uriLinkSub?.cancel();
    super.dispose();
  }

  /// Handles initial link on cold start
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingLink(initialLink);
      }
    } catch (e) {
      // Silently fail - don't crash on deep link errors
    }
  }

  /// Handles incoming link from stream (warm start) or initial link
  Future<void> _handleIncomingLink(Uri uri) async {
    try {
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) {
        return;
      }

      // Support /i/<token> and /invite/<token>
      // Also support custom scheme: lazzo://invite/TOKEN
      String? token;

      if (uri.scheme == 'lazzo' &&
          uri.host == 'invite' &&
          pathSegments.isNotEmpty) {
        // Custom scheme: lazzo://invite/TOKEN
        token = pathSegments.first;
      } else if (pathSegments.length >= 2 &&
          (pathSegments[0] == 'i' || pathSegments[0] == 'invite')) {
        // Universal/App Link: https://domain.com/i/TOKEN
        token = pathSegments[1];
      }

      if (token == null) {
        return;
      }

      // Wait for authentication to be ready (max 5 seconds)
      for (int i = 0; i < 10; i++) {
        final authState = ref.read(authProvider);
        if (authState.hasValue && authState.value != null) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Check final auth state
      final authState = ref.read(authProvider);
      if (!authState.hasValue || authState.value == null) {
        // Save the invite token to be processed after signup/login
        _pendingInviteToken = token;
        await PendingInviteService.savePendingToken(token);
        
        // Navigate to auth page - user will signup/login and then the invite will be processed
        if (_navigatorKey.currentState?.mounted == true) {
          _navigatorKey.currentState!.pushNamedAndRemoveUntil(
            AppRouter.auth,
            (route) => false,
          );
        }
        return;
      }

      // User is authenticated, attempt to accept invite
      try {
        final accept = ref.read(acceptGroupInviteProvider);
        final groupId = await accept.call(token);

        // Refresh groups to include the new group
        ref.invalidate(groupsProvider);

        // Navigate to group hub
        await _navigateToGroupHub(groupId);
        return;
      } catch (e) {
        // Handle specific errors - NEVER redirect to web as it creates loops
        // The app should handle all invite states gracefully
        final errorMessage = e.toString().toLowerCase();

        // For invalid/expired/revoked tokens, show error in-app
        // Don't redirect to web - the user already has the app
        if (errorMessage.contains('invalid token') ||
            errorMessage.contains('expired') ||
            errorMessage.contains('revoked') ||
            errorMessage.contains('not found')) {
          // User will see the normal app state
          return;
        }

        // For auth errors, the AuthWrapper will handle navigation to login
        if (errorMessage.contains('not authenticated') ||
            errorMessage.contains('unauthorized')) {
          return;
        }

        // For any other unexpected errors, stay in app
      }
    } catch (e) {
      // Silently fail - deep link errors should not crash the app
    }
  }

  /// Navigate to group hub with retry logic for navigator availability
  Future<void> _navigateToGroupHub(String groupId) async {
    // Wait for navigator to be ready (max 5 seconds)
    for (int i = 0; i < 10; i++) {
      if (_navigatorKey.currentState?.mounted == true) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Navigate to group hub
    if (_navigatorKey.currentState?.mounted == true) {
      _navigatorKey.currentState!.pushNamed(
        AppRouter.groupHub,
        arguments: {'groupId': groupId},
      );
    }
  }

  /// Process pending invite token (called after successful login)
  /// Checks both in-memory token and persisted token from SharedPreferences
  Future<void> processPendingInvite() async {
    // First check in-memory token
    String? token = _pendingInviteToken;
    _pendingInviteToken = null;
    
    // If no in-memory token, check persisted token (in case app was restarted during signup)
    if (token == null) {
      token = await PendingInviteService.getPendingToken();
    }
    
    if (token == null) return;
    
    // Clear persisted token to avoid reprocessing
    await PendingInviteService.clearPendingToken();

    try {
      final accept = ref.read(acceptGroupInviteProvider);
      final groupId = await accept.call(token);

      ref.invalidate(groupsProvider);
      await _navigateToGroupHub(groupId);
    } catch (e) {
      // Silent failure - user is in app and can retry
    }
  }
}

/// Widget que gerencia a navegação baseada no estado de autenticação
/// e aguarda o carregamento inicial dos dados da home
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _pendingInviteProcessed = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const AppLoadingScreen(),
      error: (error, stackTrace) {
        // Em caso de erro, vai para a página de auth
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRouter.auth);
        });
        return const AppLoadingScreen();
      },
      data: (user) {
        // Se não está logado, vai para a página de auth
        if (user == null) {
          _pendingInviteProcessed = false; // Reset for next login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRouter.auth);
          });
          return const AppLoadingScreen();
        }

        // Se o usuário está logado, aguarda carregamento inicial dos dados
        final nextEventAsync = ref.watch(nextEventControllerProvider);
        final confirmedEventsAsync =
            ref.watch(confirmedEventsControllerProvider);
        final groupsAsync = ref.watch(groupsProvider);

        // Verifica se os dados principais ainda estão carregando
        final isLoadingHomeData = nextEventAsync.isLoading ||
            confirmedEventsAsync.isLoading ||
            groupsAsync.isLoading;

        if (isLoadingHomeData) {
          // Mantém loading screen enquanto dados da home carregam
          return const AppLoadingScreen();
        }

        // Process any pending invite token after successful login
        // Only process once per login session
        if (!_pendingInviteProcessed) {
          _pendingInviteProcessed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _processPendingInviteAfterLogin();
          });
        }

        // Dados carregados, navega para mainLayout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRouter.mainLayout);
        });

        return const AppLoadingScreen();
      },
    );
  }

  /// Process any pending invite after successful login
  Future<void> _processPendingInviteAfterLogin() async {
    // Check for persisted pending invite token
    final token = await PendingInviteService.getPendingToken();
    if (token == null) return;

    // Clear the token first to avoid reprocessing
    await PendingInviteService.clearPendingToken();

    try {
      final accept = ref.read(acceptGroupInviteProvider);
      final groupId = await accept.call(token);

      // Refresh groups
      ref.invalidate(groupsProvider);

      // Navigate to group hub after a small delay to let MainLayout load
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRouter.groupHub,
          arguments: {'groupId': groupId},
        );
      }
    } catch (e) {
      // User will be in the app normally, they can try accepting again
    }
  }
}
