import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Serviço de analytics — wrapper sobre PostHog SDK.
/// Chamado APENAS da presentation layer (pages/providers).
/// NUNCA importar no domain layer.
///
/// Identity flow:
/// 1. App abre → PostHog gera distinct_id anónimo automaticamente
/// 2. Auth completa → chamar identify(supabaseUserId) → merge anónimo → user
/// 3. Logout → chamar reset() → novo distinct_id anónimo
class AnalyticsService {
  static Posthog get _posthog => Posthog();

  // --------------- Cache de feature flags ---------------
  static final Map<String, dynamic> _flagCache = {};
  static DateTime? _lastFlagReload;
  static const _flagReloadInterval = Duration(minutes: 30);

  // --------------- Inicialização ---------------

  /// Chamar uma vez no main.dart, DEPOIS do Supabase.initialize()
  /// PostHog inicializa automaticamente via Info.plist (iOS).
  /// Aqui apenas fazemos o primeiro reload de flags.
  static Future<void> initialize() async {
    await reloadFeatureFlags();
  }

  // --------------- Core Tracking ---------------

  /// Envia um evento para PostHog.
  /// [properties] são mescladas com global properties automaticamente.
  static Future<void> track(
    String event, {
    Map<String, Object>? properties,
  }) async {
    debugPrint('[Analytics] TRACK: $event | props: $properties');
    await _posthog.capture(
      eventName: event,
      properties: properties,
    );
  }

  // --------------- Identity ---------------

  /// Chamar quando auth completa (host ou guest).
  /// PostHog faz merge automático: anonymous distinct_id → userId.
  /// Todas as sessões anteriores são unificadas.
  static Future<void> identify(
    String userId, {
    Map<String, Object>? properties,
  }) async {
    debugPrint('[Analytics] IDENTIFY: $userId | props: $properties');
    await _posthog.identify(
      userId: userId,
      userProperties: properties,
    );
    // Reload flags para o utilizador agora identificado
    await reloadFeatureFlags();
  }

  /// Chamar no logout.
  /// Limpa distinct_id + gera novo anónimo.
  static Future<void> reset() async {
    debugPrint('[Analytics] RESET: clearing identity + flags');
    await _posthog.reset();
    _flagCache.clear();
    _lastFlagReload = null;
  }

  // --------------- Screen Tracking ---------------

  /// Enviar APENAS para ecrãs críticos (ver lista em METRICS.md).
  /// NÃO chamar em cada navegação/animação/bottom sheet.
  ///
  /// Ecrãs críticos: event_detail, event_living, event_recap,
  /// create_event, memory_ready, invite_landing,
  /// calendar (on interaction), actions (on tab select)
  static Future<void> screenViewed(
    String screenName, {
    String? eventId,
  }) async {
    debugPrint('[Analytics] SCREEN: $screenName | eventId: $eventId');
    await _posthog.screen(
      screenName: screenName,
      properties: {
        if (eventId != null) 'event_id': eventId,
      },
    );
  }

  // --------------- Feature Flags ---------------

  /// Lê flag do CACHE LOCAL — síncrono, sem network call.
  /// Chamar dentro de build() é seguro (não faz request).
  static bool isFeatureEnabled(String flagKey) {
    final value = _flagCache[flagKey];
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    return false;
  }

  /// Lê valor da flag do CACHE LOCAL — para flags multivariate.
  static String? getFeatureFlagValue(String flagKey) {
    final value = _flagCache[flagKey];
    if (value is String) return value;
    if (value is bool) return value.toString();
    return null;
  }

  /// Recarrega flags do servidor PostHog.
  /// Chamar APENAS em:
  /// - App open (initialize)
  /// - Auth complete (identify)
  /// - Timer de 30 min (se app estiver ativa)
  /// NÃO chamar em cada screen transition ou build().
  static Future<void> reloadFeatureFlags() async {
    try {
      await _posthog.reloadFeatureFlags();

      // Lê os valores atualizados para o cache local.
      // posthog_flutter v5 não expõe getAllFlags(), então
      // precisamos ler cada flag individualmente.
      for (final flagKey in _knownFlags) {
        final value = await _posthog.getFeatureFlag(flagKey);
        if (value != null) {
          _flagCache[flagKey] = value;
        }
      }

      _lastFlagReload = DateTime.now();
    } catch (_) {
      // Silently fail — flags mantêm valores do cache anterior.
      // Em caso de erro de rede, melhor usar valores antigos que crashar.
    }
  }

  /// Verifica se é hora de recarregar flags (30 min interval).
  /// Chamar num timer periódico ou no app lifecycle (app resumed).
  static Future<void> reloadFlagsIfNeeded() async {
    if (_lastFlagReload == null) {
      await reloadFeatureFlags();
      return;
    }
    final elapsed = DateTime.now().difference(_lastFlagReload!);
    if (elapsed >= _flagReloadInterval) {
      await reloadFeatureFlags();
    }
  }

  // Lista de flags conhecidas — atualizar quando adicionares novas flags.
  // Estas flags devem corresponder exatamente às criadas no PostHog dashboard.
  static const _knownFlags = <String>[
    'auth_wall_placement',
    'upload_nudge_variant',
    //'recap_cta_variant',
    //'rsvp_ui_variant',
    //'memories_first_flow',
  ];
}
