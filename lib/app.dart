// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/routes/app_router.dart';
import 'package:app/shared/themes/app_theme.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/config/app_config.dart';
import 'package:app/features/group_invites/presentation/providers/accept_group_invites_providers.dart';
//import 'package:app/services/notification_service.dart';

// Deep link packages
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

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
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) {
        // Em caso de erro, vai para a página de auth
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRouter.auth);
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      data: (user) {
        // Se o usuário está logado, vai para o layout principal
        // Se não está logado, vai para a página de auth
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRouter.mainLayout);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRouter.auth);
          });
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
