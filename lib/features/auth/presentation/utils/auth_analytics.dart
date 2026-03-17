import '../../domain/entities/user.dart' as domain;
import 'package:lazzo/services/analytics_service.dart';

/// Utilitários de analytics relacionados com auth (login/signup).
///
/// Mantém num único sítio a lógica de:
/// - identify no PostHog
/// - evento auth_completed com is_new_user
Future<void> trackAuthCompleted({
  required domain.User user,
  required bool isNewUser,
}) async {
  await AnalyticsService.identify(
    user.id,
    properties: {
      'email': user.email,
      'role': 'host',
      'platform': 'app',
      if (user.name != null && user.name!.isNotEmpty) r'$name': user.name!,
    },
  );

  await AnalyticsService.track(
    'auth_completed',
    properties: {
      'auth_type': 'email_passwordless',
      'is_new_user': isNewUser,
      'platform': 'ios',
    },
  );
}

