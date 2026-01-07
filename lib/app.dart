// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazzo/routes/app_router.dart';
import 'package:lazzo/shared/themes/app_theme.dart';
import 'package:lazzo/features/auth/presentation/providers/auth_provider.dart';
import 'package:lazzo/shared/components/loading/app_loading_screen.dart';
import 'package:lazzo/features/home/presentation/providers/home_event_providers.dart';
import 'package:lazzo/features/groups/presentation/providers/groups_provider.dart';

class LazzoApp extends ConsumerStatefulWidget {
  const LazzoApp({super.key});

  @override
  ConsumerState<LazzoApp> createState() => _LazzoAppState();
}

class _LazzoAppState extends ConsumerState<LazzoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final dynamic _appLinks;
  StreamSubscription<dynamic>? _appLinksSub;

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
    _handleInitialAppLink();

    try {
      final stream = (_appLinks as dynamic).appLinksStream as Stream<dynamic>?;
      if (stream != null) {
        _appLinksSub = stream.listen((dynamic link) {
          if (link != null) _handleIncomingLink(Uri.parse(link.toString()));
        }, onError: (_) {});
      }
    } catch (_) {
      // If the runtime API differs, we silently ignore subscription setup.
    }
  }

  @override
  void dispose() {
    _appLinksSub?.cancel();
    super.dispose();
  }
  Future<void> _handleInitialAppLink() async {
    try {
      final initial = await (_appLinks as dynamic).getInitialAppLink();
      if (initial != null) {
        _handleIncomingLink(Uri.parse(initial.toString()));
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    try {
      final segments = uri.pathSegments;
      
      if (segments.isEmpty) {
        return;
      }

      // Support /i/<token> and /invite/<token>
      if (segments.length >= 2 && (segments[0] == 'i' || segments[0] == 'invite')) {
        final token = segments[1];

        // Attempt to accept invite
        try {
          final accept = ref.read(acceptGroupInviteProvider);
          final groupId = await accept.call(token);

          // Navigate to group hub
          _navigatorKey.currentState?.pushNamed(
            AppRouter.groupHub,
            arguments: {'groupId': groupId},
          );
          return;
        } catch (e) {
          // If accepting failed, open landing page as fallback
          final landing = '${AppConfig.invitesBaseUrl}/i/$token';
          final uriLanding = Uri.parse(landing);
          if (await canLaunchUrl(uriLanding)) {
            await launchUrl(uriLanding, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      debugPrint('ERROR handling incoming link: $e');
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
