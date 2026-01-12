// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lazzo/routes/app_router.dart';
import 'package:lazzo/shared/themes/app_theme.dart';
import 'package:lazzo/features/auth/presentation/providers/auth_provider.dart';
import 'package:lazzo/shared/components/loading/app_loading_screen.dart';
import 'package:lazzo/features/home/presentation/providers/home_event_providers.dart';
import 'package:lazzo/features/groups/presentation/providers/groups_provider.dart';
import 'package:lazzo/config/app_config.dart';
import 'package:lazzo/features/group_invites/presentation/providers/accept_group_invites_providers.dart';

class LazzoApp extends ConsumerStatefulWidget {
  const LazzoApp({super.key});

  @override
  ConsumerState<LazzoApp> createState() => _LazzoAppState();
}

class _LazzoAppState extends ConsumerState<LazzoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _uriLinkSub;

  @override
  Widget build(BuildContext context) {
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
        debugPrint('[DeepLinks] Error on uri stream: $error');
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
        debugPrint('[DeepLinks] Initial link received: $initialLink');
        _handleIncomingLink(initialLink);
      }
    } catch (e) {
      debugPrint('[DeepLinks] Error getting initial link: $e');
    }
  }

  /// Handles incoming link from stream (warm start) or initial link
  Future<void> _handleIncomingLink(Uri uri) async {
    try {
      debugPrint('[DeepLinks] Handling incoming link: ${uri.toString()}');

      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) {
        debugPrint('[DeepLinks] Empty path segments, ignoring');
        return;
      }

      // Support /i/<token> and /invite/<token>
      if (pathSegments.length >= 2 &&
          (pathSegments[0] == 'i' || pathSegments[0] == 'invite')) {
        final token = pathSegments[1];
        debugPrint('[DeepLinks] Extracted token: $token');

        // Attempt to accept invite via provider
        try {
          final accept = ref.read(acceptGroupInviteProvider);
          debugPrint(
              '[DeepLinks] Calling acceptGroupInviteProvider with token: $token');

          final groupId = await accept.call(token);

          debugPrint(
              '[DeepLinks] Invite accepted. GroupId: $groupId. Navigating...');

          // Navigate to group hub after first frame to ensure navigation stack is ready
          if (mounted) {
            _navigatorKey.currentState?.pushNamed(
              AppRouter.groupHub,
              arguments: {'groupId': groupId},
            );
            debugPrint('[DeepLinks] Navigation to group hub completed');
          }
          return;
        } catch (e) {
          debugPrint(
              '[DeepLinks] Error accepting invite: $e. Opening fallback landing page...');

          // If accepting failed, open landing page as fallback
          final landing = '${AppConfig.invitesBaseUrl}/i/$token';
          final uriLanding = Uri.parse(landing);
          if (await canLaunchUrl(uriLanding)) {
            debugPrint('[DeepLinks] Launching fallback landing page: $landing');
            await launchUrl(uriLanding, mode: LaunchMode.externalApplication);
          } else {
            debugPrint('[DeepLinks] Cannot launch fallback URL: $landing');
          }
        }
      } else {
        debugPrint(
            '[DeepLinks] Path does not match /i/<token> or /invite/<token> pattern');
      }
    } catch (e) {
      debugPrint('[DeepLinks] ERROR handling incoming link: $e');
    }
  }
}

/// Widget que gerencia a navegação baseada no estado de autenticação
/// e aguarda o carregamento inicial dos dados da home
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final groupsAsync = ref.watch(groupsProvider);

        // Verifica se os dados principais ainda estão carregando
        final isLoadingHomeData = nextEventAsync.isLoading ||
            confirmedEventsAsync.isLoading ||
            groupsAsync.isLoading;

        if (isLoadingHomeData) {
          // Mantém loading screen enquanto dados da home carregam
          return const AppLoadingScreen();
        }

        // Dados carregados, navega para mainLayout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRouter.mainLayout);
        });

        return const AppLoadingScreen();
      },
    );
  }
}
