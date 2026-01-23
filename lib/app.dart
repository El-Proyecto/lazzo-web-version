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
import 'package:lazzo/services/push_notification_initializer.dart';

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
      debugPrint(
          '🔗 Deep link recebido: $uri (scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path})');

      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) {
        debugPrint('❌ Path vazio no deep link');
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
        debugPrint('✅ Token extraído de custom scheme: $token');
      } else if (pathSegments.length >= 2 &&
          (pathSegments[0] == 'i' || pathSegments[0] == 'invite')) {
        // Universal/App Link: https://domain.com/i/TOKEN
        token = pathSegments[1];
        debugPrint('✅ Token extraído de universal link: $token');
      }

      if (token == null) {
        debugPrint('❌ Não foi possível extrair token do deep link');
        return;
      }

      debugPrint('✅ Token extraído: $token');

      // Wait for authentication to be ready (max 5 seconds)
      for (int i = 0; i < 10; i++) {
        final authState = ref.read(authProvider);
        if (authState.hasValue && authState.value != null) {
          debugPrint('✅ User autenticado, processando convite...');
          break;
        }
        debugPrint('⏳ Aguardando autenticação... (tentativa ${i + 1}/10)');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Check final auth state
      final authState = ref.read(authProvider);
      if (!authState.hasValue || authState.value == null) {
        debugPrint('⚠️ User não autenticado - redirecionando para web');
        // User is not logged in - redirect to web landing page
        // This is the ONLY case where we redirect to web
        final landing = '${AppConfig.invitesBaseUrl}/i/$token';
        final uriLanding = Uri.parse(landing);
        if (await canLaunchUrl(uriLanding)) {
          await launchUrl(uriLanding, mode: LaunchMode.externalApplication);
        }
        return;
      }

      // User is authenticated, attempt to accept invite
      debugPrint('✅ Aceitando convite...');
      try {
        final accept = ref.read(acceptGroupInviteProvider);
        final groupId = await accept.call(token);
        debugPrint('✅ Convite aceito! Group ID: $groupId');

        // Refresh groups to include the new group
        ref.invalidate(groupsProvider);

        // Navigate to group hub
        await _navigateToGroupHub(groupId);
        return;
      } catch (e) {
        debugPrint('❌ Erro ao aceitar convite: $e');

        // Handle specific errors - NEVER redirect to web as it creates loops
        // The app should handle all invite states gracefully
        final errorMessage = e.toString().toLowerCase();

        // For invalid/expired/revoked tokens, show error in-app
        // Don't redirect to web - the user already has the app
        if (errorMessage.contains('invalid token') ||
            errorMessage.contains('expired') ||
            errorMessage.contains('revoked') ||
            errorMessage.contains('not found')) {
          debugPrint('⚠️ Token inválido/expirado - mostrando erro na app');
          // User will see the normal app state
          // Could show a snackbar/banner here if needed
          return;
        }

        // For auth errors, the AuthWrapper will handle navigation to login
        if (errorMessage.contains('not authenticated') ||
            errorMessage.contains('unauthorized')) {
          debugPrint('⚠️ Erro de autenticação - AuthWrapper vai tratar');
          return;
        }

        // For any other unexpected errors, stay in app
        debugPrint('⚠️ Erro inesperado - permanecendo na app');
      }
    } catch (e) {
      debugPrint('❌ Erro geral ao processar deep link: $e');
      // Silently fail - deep link errors should not crash the app
    }
  }

  /// Navigate to group hub with retry logic for navigator availability
  Future<void> _navigateToGroupHub(String groupId) async {
    // Wait for navigator to be ready (max 5 seconds)
    for (int i = 0; i < 10; i++) {
      if (_navigatorKey.currentState?.mounted == true) {
        debugPrint('✅ Navigator ready');
        break;
      }
      debugPrint('⏳ Aguardando navigator... (tentativa ${i + 1}/10)');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Navigate to group hub
    if (_navigatorKey.currentState?.mounted == true) {
      debugPrint('✅ Navegando para group hub...');
      _navigatorKey.currentState!.pushNamed(
        AppRouter.groupHub,
        arguments: {'groupId': groupId},
      );
    } else {
      debugPrint('❌ Navigator não disponível após espera');
    }
  }

  /// Process pending invite token (called after successful login)
  Future<void> processPendingInvite() async {
    final token = _pendingInviteToken;
    if (token == null) return;

    _pendingInviteToken = null; // Clear to avoid reprocessing
    debugPrint('✅ Processando convite pendente: $token');

    try {
      final accept = ref.read(acceptGroupInviteProvider);
      final groupId = await accept.call(token);
      debugPrint('✅ Convite pendente aceito! Group ID: $groupId');

      ref.invalidate(groupsProvider);
      await _navigateToGroupHub(groupId);
    } catch (e) {
      debugPrint('❌ Erro ao processar convite pendente: $e');
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
