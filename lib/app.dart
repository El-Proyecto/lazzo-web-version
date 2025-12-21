// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/routes/app_router.dart';
import 'package:app/shared/themes/app_theme.dart';
import 'package:app/features/auth/presentation/providers/auth_provider.dart';
import 'package:app/services/push_notification_service.dart';

class LazzoApp extends ConsumerStatefulWidget {
  const LazzoApp({super.key});

  @override
  ConsumerState<LazzoApp> createState() => _LazzoAppState();
}

class _LazzoAppState extends ConsumerState<LazzoApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializePushNotifications();
  }

  Future<void> _initializePushNotifications() async {
    final pushService = ref.read(pushNotificationServiceProvider);
    
    await pushService.initialize(
      onDeeplinkReceived: (deeplink) {
                _navigateToDeeplink(deeplink);
      },
    );
  }

  void _navigateToDeeplink(String deeplink) {
    // Parse deeplink format: lazzo://event/{eventId} or lazzo://group/{groupId}
    final uri = Uri.parse(deeplink);
    
    if (uri.host == 'event' || uri.host == 'events') {
      final eventId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (eventId != null) {
        _navigatorKey.currentState?.pushNamed(
          '/event',
          arguments: {'eventId': eventId},
        );
      }
    } else if (uri.host == 'group' || uri.host == 'groups') {
      final groupId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (groupId != null) {
        _navigatorKey.currentState?.pushNamed(
          '/group-hub',
          arguments: {'groupId': groupId},
        );
      }
    } else if (uri.host == 'memory-viewer') {
      final eventId = uri.queryParameters['eventId'];
      if (eventId != null) {
        _navigatorKey.currentState?.pushNamed(
          '/memory-viewer',
          arguments: {'eventId': eventId},
        );
      }
    }
    // Add more deeplink handlers as needed
  }

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
