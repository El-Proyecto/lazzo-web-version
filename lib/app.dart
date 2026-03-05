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
// LAZZO 2.0: Groups/group_invites removed
import 'package:lazzo/services/push_notification_initializer.dart';
import 'package:lazzo/services/analytics_service.dart';
import 'package:lazzo/services/pending_invite_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LazzoApp extends ConsumerStatefulWidget {
  const LazzoApp({super.key});

  @override
  ConsumerState<LazzoApp> createState() => _LazzoAppState();
}

class _LazzoAppState extends ConsumerState<LazzoApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _uriLinkSub;
  Timer? _flagReloadTimer;

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
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();

    // PostHog: reload feature flags every 30 minutes
    _flagReloadTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => AnalyticsService.reloadFlagsIfNeeded(),
    );

    // Track app opened (cold start)
    AnalyticsService.track('app_opened', properties: {
      'source': 'organic',
      'platform': 'ios',
    });

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
    _flagReloadTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _uriLinkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App voltou ao foreground — reload flags + track app_opened
      AnalyticsService.reloadFlagsIfNeeded();
      AnalyticsService.track('app_opened', properties: {
        'source': 'organic',
        'platform': 'ios',
      });
    }
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

      // Handle event deeplinks (e.g., lazzo://event/<eventId>)
      if (uri.scheme == 'lazzo' &&
          uri.host == 'event' &&
          pathSegments.isNotEmpty) {
        final eventId = pathSegments.first;
        await _navigateToMemoryReady(eventId);
        return;
      }

      // Handle invite deep links:
      // - Custom scheme: lazzo://invite/<token>
      // - Universal link: https://lazzo.app/i/<token>
      String? inviteToken;

      if (uri.scheme == 'lazzo' &&
          uri.host == 'invite' &&
          pathSegments.isNotEmpty) {
        inviteToken = pathSegments.first;
      } else if (pathSegments.length >= 2 && pathSegments[0] == 'i') {
        inviteToken = pathSegments[1];
      }

      if (inviteToken != null && inviteToken.isNotEmpty) {
        await _handleInviteToken(inviteToken);
        return;
      }
    } catch (e) {
      // Silently fail - deep link errors should not crash the app
    }
  }

  /// Handle an invite token from a deep link
  Future<void> _handleInviteToken(String token) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      // User not logged in — save token and let auth flow process it after login
      await PendingInviteService.savePendingToken(token);
      return;
    }

    // User is authenticated — accept the invite and navigate to the event
    try {
      final response = await client.rpc(
        'accept_event_invite_by_token',
        params: {'p_token': token},
      );

      if (response is List && response.isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        final eventId = data['event_id'] as String;
        await _navigateToEvent(eventId);
      }
    } catch (e) {
      // If accept fails (expired/invalid token), silently ignore
    }
  }

  /// Navigate to event page (generic — the page determines living/recap/etc.)
  Future<void> _navigateToEvent(String eventId) async {
    // Wait for navigator to be ready (max 5 seconds)
    for (int i = 0; i < 10; i++) {
      if (_navigatorKey.currentState?.mounted == true) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_navigatorKey.currentState?.mounted == true) {
      _navigatorKey.currentState!.pushNamed(
        AppRouter.event,
        arguments: {'eventId': eventId},
      );
    }
  }

  /// Navigate to memory ready page with retry logic for navigator availability
  Future<void> _navigateToMemoryReady(String memoryId) async {
    // Wait for navigator to be ready (max 5 seconds)
    for (int i = 0; i < 10; i++) {
      if (_navigatorKey.currentState?.mounted == true) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Navigate to memory ready page
    if (_navigatorKey.currentState?.mounted == true) {
      _navigatorKey.currentState!.pushNamed(
        AppRouter.memoryReady,
        arguments: {'memoryId': memoryId},
      );
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRouter.auth);
          });
          return const AppLoadingScreen();
        }

        // Se o usuário está logado, aguarda carregamento inicial dos dados
        final nextEventAsync = ref.watch(nextEventControllerProvider);
        final confirmedEventsAsync =
            ref.watch(confirmedEventsControllerProvider);

        // Verifica se os dados principais ainda estão carregando
        final isLoadingHomeData = nextEventAsync.isLoading ||
            confirmedEventsAsync.isLoading;

        if (isLoadingHomeData) {
          // Mantém loading screen enquanto dados da home carregam
          return const AppLoadingScreen();
        }

        // Dados carregados, navega para mainLayout
        // Also process any pending invite token (from deep link before auth)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRouter.mainLayout);
          _processPendingInvite();
        });

        return const AppLoadingScreen();
      },
    );
  }

  /// Process a pending invite token saved before authentication
  Future<void> _processPendingInvite() async {
    if (_pendingInviteProcessed) return;
    _pendingInviteProcessed = true;

    try {
      final token = await PendingInviteService.getPendingToken();
      if (token == null || token.isEmpty) return;

      // Clear immediately to avoid re-processing
      await PendingInviteService.clearPendingToken();

      final client = Supabase.instance.client;
      final response = await client.rpc(
        'accept_event_invite_by_token',
        params: {'p_token': token},
      );

      if (response is List && response.isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        final eventId = data['event_id'] as String;

        // Small delay to let mainLayout mount first
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushNamed(
            AppRouter.event,
            arguments: {'eventId': eventId},
          );
        }
      }
    } catch (e) {
      // Silently fail — expired/invalid tokens are expected
    }
  }
}
