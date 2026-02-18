# 🔍 AUDITORIA: Data Retrieval & UX Fluida
**Lazzo Mobile App (Flutter) — Foco em Performance & Practices**  
**Data:** 16/02/2026 | **Versão:** LAZZO 2.0

---

## 📋 MAPAS DE FLUXOS & TRIGGERS DE REDE

### 1. **App Launch / Cold Start**
| Fase | Endpoints Chamados | Ordem | Bloqueio UI? | Payload Tamanho | Observações |
|------|------|-------|--------|--------|---------|
| Auth Check | (auth.uid() do Supabase) | 1 | ❌ Async | N/A | Via `AuthWrapper` |
| Home Page Init | `home_events_view` (next event) | 2 | ✅ **BLOQUEIA** | ~5KB | Fetch síncrono em provider init |
| Confirmed Events | `home_events_view` + count RPC | 3 | ✅ **BLOQUEIA** | ~20KB | Múltiplas chamadas paralelas |
| Pending Events | `home_events_view` + count RPC | 4 | ✅ **BLOQUEIA** | ~20KB | |
| Memorias Recentes | `events` + `event_photos` (2 queries) | 5 | ✅ **BLOQUEIA** | ~10KB | Nested queries sem índices |
| Notificações | `notifications` + join `users` | 6 | ✅ **BLOQUEIA** | ~8KB | Sem paginação |

**⚠️ Problema Principal:** Ecrã fica **branco 2-4s** até dados chegarem. Sem skeleton screens.

---

### 2. **Login / Pós-Login**
| Trigger | Endpoints | Dependências | UI | Payload |
|---------|-----------|---|---|---------|
| Auth Success | `get_or_create_user` | —— | ❌ Async | <1KB |
| Profile Fetch | `users` table SELECT | Auth done | ✅ **BLOQUEIA** | ~3KB |
| Avatar URL Sign | RPC `get_avatar_signed_url` (batch) | Profile done | ✅ **BLOQUEIA** 500ms | ~100B/avatar |
| Home Load | (5-6 endpoints acima) | Profile done | ✅ **BLOQUEIA** | ~70KB total |

**⚠️ Problema:** Retry hard-coded (300ms) no ProfileDataSource. Sem exponential backoff.

---

### 3. **Home Page (Scroll)**
```
┌─────────────────────────────┐
├─ Search Bar (disabled)      │ ← Não faz nada (é só UI)
├─ Next Event Card           │ ← from nextEventControllerProvider (cached? não)
│  └─ Attendee Avatars       │ ← Lazy? **NÃO** — antecipado no fetch
├─ Confirmed Events (5-10)  │ ← Paginação? SIM (offset-based)
├─ Pending Events (5-10)    │ ← Paginação? SIM (offset-based)
├─ Living/Recap Events      │ ← Often empty (UI ok)
└─ Recent Memories (3)      │ ← Separate query, **MÚLTIPLO na data_source**
   └─ Cover Photos Storage URL │ ← **Síncrono por memória** (sem batch)
```

**⚠️ Problemas:**
- **Sem deduplicação:** `nextEventControllerProvider` + `confirmedEventsControllerProvider` ambas chamam `fetchNextEvent()` + `fetchConfirmedEvents()` — pode haver race condition
- **Avatar URLs antecipadas:** Todas as URLs de avatares são signed no fetch (em lote), mesmo que não sejam visíveis inicialmente
- **DB local:** NENHUM. Tudo é network→memory. Sem offline-first

---

### 4. **Tab Switching / Navigate to Page**
```
Event Detail Page:
  └─ event_providers.dart: eventDetailProvider(eventId) 
     └─ Supabase: events where id = ?  (OK, pequeno)
  └─ eventRsvpsProvider(eventId)
     └─ Supabase: event_guest_rsvps WHERE event_id = eventId (Paginado? NÃO)
  └─ eventPhotosProvider(eventId)
     └─ No limit! Pode vir 1000+ fotos (⚠️ HUGE PAYLOAD)

Manage Guests Page:
  └─ eventRsvpsProvider(eventId) (sem paginação)
  └─ Photo count (vem junto no event_detail)
```

**⚠️ Problemas:**
- Photos podem vir SEM LIMIT — lê TODA a tabela
- Sem paginação no guest list (eventRsvpsProvider)

---

### 5. **Search**
```
home_search_page.dart:
  └─ Simples: `events.ilike('name', '%query%')`
  Sem:
    ✗ Debouncing
    ✗ Min 3 caracteres filter
    ✗ Paginação
    ✗ Cache de buscas anteriores
```

**⚠️ Problema:** Cada keystroke = 1 request. Com network lento, 5 keystroke = 5 requests paralelos pendentes.

---

### 6. **Pull-to-Refresh**
```
HomePage.didChangeDependencies() ou RefreshIndicator.onRefresh():
  └─ ref.invalidate(nextEventControllerProvider) ← Invalida
  └─ ref.invalidate(confirmedEventsControllerProvider)
  └─ ref.invalidate(homeEventsControllerProvider)
  └─ ref.invalidate(livingAndRecapEventsControllerProvider)
  └─ ref.invalidate(todosControllerProvider)
  └─ ref.invalidate(recentMemoriesControllerProvider)
     
RESULTADO: 6 FutureProviders refetch em paralelo
```

**⚠️ Problema:** Sem "stale-while-revalidate". Mostra vazio enquanto refetch. Vem de novo de zero.

---

### 7. **App Resume (Warm Start)**
```
app.dart: handleIncomingLink() dispatcher para deep links
  └─ Navigate para event/group/etc
  
Em background, Supabase realtime listeners (se existentes):
  └─ **NÃO ENCONTREI NENHUM** — App USA model-centric subscriptions (Riverpod)
```

**⚠️ Problema:** Sem realtime updates. Se alguém vota enquanto você está no app, não vê até refresh manual.

---

### 8. **Paginação (Events List Page)**
```
events_list_page.dart:
  ✅ Bom: StateNotifier + offset-based + loadMore trigger
  ✅ Page size = 20 (reasonable)
  ✅ Infinite scroll trigger = 200px antes do fim
  
Porém:
  ⚠️ SEM deduplicação: Se user chegar ao fim e faz pull-to-refresh,
     pode haver overlap se offset não for resetado corretamente
```

---

## 🏗️ ARQUITETURA DA CAMADA DE DADOS

### Clean Architecture (✅ Existe)
```
presentation/pages → presentation/providers (Riverpod)
                  ↓
                presentation/widgets
                
domain/usecases → domain/repositories (abstract)
    ↓
data/repositories/impl → data/data_sources (remote)
    ↓
    Supabase client
```

### Avaliação:

| Aspecto | Status | Observação |
|---------|--------|-----------|
| Repository > DataSource | ✅ Existe | Bom pattern |
| UI → Domain Layer | ✅ Existe | Via Riverpod providers |
| Cancelamento requests | ❌ NÃO | Nenhum evidence de CancelToken |
| Local DB (Hive/SQLite) | ❌ NÃO | Apenas shared_preferences (strings) |
| Request deduplication | ❌ PARCIAL | Riverpod autoDispose faz cache, mas invalida tudo ao mudar de aba |
| Timeouts globais | ❌ NÃO | Supabase timout? Default (30s?) |
| Retries com backoff | ⚠️ RARO | Só profile_remote_data_source (hard-coded 300ms) |

---

## 💾 CACHE E ESTRATÉGIA DE ATUALIZAÇÃO

### Memory Cache (In-Memory)
```dart
// ✅ Encontrado EM:
event_invites/data_sources/event_invite_remote_data_source.dart
group_invites/data_sources/group_invite_remote_data_source.dart

// Pattern: 5-minuto TTL
final Map<String, ({Model model, DateTime cachedAt})> _cache = {};

if (cache_age < 5 minutes && not_expired) {
  return cached_model;
}
```

**❌ Problema:** SÓ invites. Eventos, fotos, etc. — sem cache.

### DB Local
**NENHUM.** Projeto não usa:
- ❌ Hive
- ❌ SQLite / Drift
- ❌ Isar
- ❌ ObjectBox

**Impacto:**
- Sem offline-first
- Home sempre branca ao abrir (sem cache local)
- Imagens: sem arquivo em disco (só em memory Image cache do Flutter)

### Invalidação por Entidade
```dart
// Riverpod autoDispose:
final nextEventControllerProvider = FutureProvider.autoDispose<HomeEventEntity?>((ref) async { ... });

// → Limpa após ~5 min de não-uso.
// → MAS: didChangeDependencies invalida TUDO ao voltar à Home.
```

**❌ Problema:** All-or-nothing. Não há invalidação seletiva (ex: "só invalidar este evento").

---

## 📦 PAYLOAD E PERFORMANCE

### Home Page Inicial
**Total Network:**
- `home_events_view` (next + confirmed + pending): **~65KB**
  - 5 eventos × 13KB média
- `event_photos` (count/recent): **5KB**
- `notifications`: **~3KB**
- Avatares (batch convert URLs): **~2KB**

**TOTAL: ~75KB** em **6-8 round-trips paralelos**

**TTI (Time to Interactive):**
- Debug mode: **2-4 segundos** (network + build)
- Release mode (est.): **1-2 segundos**

### Sem Skeleton Screens
```dart
loading: () => CircularProgressIndicator(), // ← Ecrã branco!
```

**⚠️ Problema:** Aparência "congelada" nos primeiros 2s.

### Images
```dart
// home_event_card.dart + event_full_card.dart
Image.network(coverPhotoUrl)  // ❌ Sem caching
```

**Impacto:**
- First load: 300-500ms por imagem
- Sem lazy loading: Carrega quando widget build(CancelToken, não quando visível
- Network reuse? Depende do Image cache do Flutter (default: ~500MB, não persistent)

---

## 🛡️ ROBUSTEZ

### Timeouts
```dart
// ❌ NÃO ENCONTRADO timeout global
Supabase.instance.client // → Default supabase-flutter timeout?
```

**Risco:** Requests hangueiam indefinidamente em rede lenta/off

### Retries
```dart
// ✅ Encontrado EM:
profile_remote_data_source.dart:
  if (user == null) {
    await Future.delayed(const Duration(milliseconds: 300));
    // Retry uma vez
  }

// ❌ SEM exponential backoff, SEM máximo de retries
```

### Error Handling
```dart
catch (e) { 
  rethrow;  // ← Propagates ao UI
}
// UI:
error: (error, _) => const SizedBox.shrink(), // ← Ecrã vazia!
```

**⚠️ Problema:** Erros causam UI vazia, sem mensagem ao user.

### 401/Refresh Token
```dart
// ❌ NÃO ENCONTRADO
// Supabase-flutter handles automaticamente,
// MAS: sem fallback UI ou notificação
```

**Risco:** User vê erro silencioso si token expirou durante sessão.

---

## 📱 DB LOCAL

**Status: INEXISTENTE**

**Impacto:**
- Home sempre faz fetch (sem cache em disco)
- Sem offline-first
- Performance = 100% dependente de network
- Imagens: máximo ~500MB em memory (device reboot limpa)

---

## 📊 PROBLEMAS PRIORIZADOS

### 🔴 P0 — CRÍTICO

#### 1. **Ecrã Branco no App Launch (2-4s)**
- **Localização:** `home.dart:build()` + 6 providers loading
- **Causa:** Todos os 6 FutureProviders esperados antes de render
- **Impacto:** UX ruim, perception de "bug"
- **Severidade:** Alto — first impression negativa

#### 2. **Sem Cancelamento de Requests**
- **Localização:** todas data_sources
- **Causa:** Supabase client padrão sem CancelToken
- **Impacto:** Memory leaks, updates fora de contexto (ex: navigate longe && fetch ainda chega)
- **Exemplo:** 
  ```dart
  // User triggered loadMore 5x rapidamente
  // → 5 requests paralelos pendentes
  // → UserAsync tem race condition
  ```
- **Severidade:** Alto — memory leaks & stale updates

#### 3. **Fotos SEM Limite (Payload Gigante)**
- **Localização:** `event_photo_repository_impl.dart`, `event_remote_data_source.dart`
- **Problema:** 
  ```dart
  final photos = await client
    .from('event_photos')
    .select()
    .eq('event_id', eventId)
    // ❌ SEM .limit()
  ```
- **Impacto:** Event com 1000 fotos = 10MB+ payload, OOM risks
- **Severidade:** Alto

#### 4. **Sem DB Local / Offline-first**
- **Localização:** Toda a app
- **Problema:** Home sempre faz network fetch
- **Impacto:** 
  - Sem cache em disco
  - Não funciona sem internet
  - TTFB (Time to First Byte) sempre 1-4s
- **Severidade:** Alto

---

### 🟠 P1 — IMPORTANTE

#### 5. **Múltiplos Fetches do Mesmo Recurso (Race Condition)**
- **Localização:** `home_event_providers.dart`
- **Causa:**
  ```dart
  final results = await Future.wait([
    ref.watch(getConfirmedEventsProvider)(),
    ref.watch(nextEventControllerProvider.future),  // ← nextEvent fetched 2x!
  ]);
  ```
- **Impacto:** `nextEvent` vem de 2 fontes, pode vler diferentes valores
- **Severidade:** Médio — UI inconsistency

#### 6. **Search SEM Debouncing**
- **Localização:** `home_search_page.dart`
- **Problema:** Cada keystroke = 1 request
- **Impacto:** 10 keys = 10 requests ao mesmo tempo
- **Severidade:** Médio — wasted bandwidth

#### 7. **Sem Skeleton Screens**
- **Localização:** Todos os `.when(loading: ...)` em `home.dart`
- **Problema:** 
  ```dart
  loading: () => CircularProgressIndicator(), // ← Ecrã vazia!
  ```
- **Impacto:** UX pareça congelada
- **Severidade:** Médio

#### 8. **Retries SEM Exponential Backoff**
- **Localização:** `profile_remote_data_source.dart`
- **Problema:** Hard-coded 300ms retry sem progressão
- **Impacto:** Retry storms em rede instável  
- **Severidade:** Médio

#### 9. **Sem Timeouts Globais**
- **Localização:** Todas data_sources (Supabase client)
- **Problema:** Requests podem hanguer indefinidamente
- **Impacto:** App "freezes" em rede lenta/off
- **Severidade:** Médio-Alto

#### 10. **Pull-to-Refresh SEM Stale-While-Revalidate**
- **Localização:** `home.dart:RefreshIndicator`
- **Problema:** Invalida tudo, mostra vazio enquanto refetch
- **Impacto:** Flashing/flicker UI
- **Severidade:** Médio

---

### 🟡 P2 — MELHORIAS

#### 11. **Guest List Sem Paginação**
- **Localização:** `event_rsvps_provider.dart` → fetchRsvps()
- **Problema:** Sem .limit() em eventos com 100+ guests
- **Severidade:** Baixo (menos comum ter 100+ guests)

#### 12. **Imagens SEM Lazy Loading**
- **Localização:** `home_event_card.dart`, cards
- **Problema:** Carrega avatar/cover quando widget build(), não quando visível
- **Severidade:** Baixo (imagens pequenas)

#### 13. **Sem Request Deduplication (POST)**
- **Localização:** **Não aplicável** — só queries GETs
- **Descarta:** P2

#### 14. **Logging / Métricas Ausentes**
- **Localização:** Toda a app
- **Problema:** Sem observabilidade de TTFB, error rates, request counts
- **Severidade:** Baixo (mas importante para debugging)

---

## 🎯 PLANO DE EXECUÇÃO (5-10 PASSOS)

### **FASE 1: Criticidade (P0) — Semana 1**

#### Passo 1️⃣ — Adicionar DB Local + Cache Disk
**Objetivo:** Offline-first, eliminar "ecrã branca"

**Ações:**
1. Adicionar **Hive** ao pubspec.yaml
2. Criar `boxes/` folder com schemas:
   - `HomeEventsBox` (events + metadata)
   - `MemoriesBox` (recent memories)
   - `NotificationsBox`
3. Reescrever `home_event_providers.dart`:
   ```dart
   final homeEventsProvider = FutureProvider.autoDispose((ref) async {
     final box = Hive.box<HomeEvent>('homeEvents');
     
     // 1. Return cached (immediate)
     if (box.isNotEmpty && _cacheValid()) {
       yield box.values.toList(); // ← Show immediately
     }
     
     // 2. Fetch fresh (background)
     final fresh = await ref.watch(getHomeFreshEventsProvider).future;
     
     // 3. Update box + yield
     await box.clear();
     await box.addAll(fresh);
     return fresh;
   });
   ```
4. Testar: Home mostra dados anteriores imediatamente, depois atualiza

**Estimativa:** 6 hours  
**Impacto:** ⭐⭐⭐⭐⭐ (eliminaria ecrã branca)

---

#### Passo 2️⃣ — Implement Request Cancellation
**Objetivo:** Evitar memory leaks & stale updates

**Ações:**
1. Criar `services/http_client_service.dart`:
   ```dart
   class HttpClientService {
     final Map<String, CancelToken> _tokens = {};
     
     CancelToken getToken(String key) {
       _tokens[key]?.cancel();
       _tokens[key] = CancelToken();
       return _tokens[key]!;
     }
     
     void cancelAll() => _tokens.values.forEach((t) => t.cancel());
   }
   ```
2. Injetar via Riverpod:
   ```dart
   final httpClientProvider = Provider((ref) => HttpClientService());
   ```
3. Usar em data_sources:
   ```dart
   final response = await client
     .from('events')
     .select()
     .withConverter(
       cancelToken: ref.watch(httpClientProvider).getToken('events_fetch')
     );
   ```
4. Cleanup no provider dispose:
   ```dart
   ref.onDispose(() {
     ref.read(httpClientProvider).cancelAll();
   });
   ```

**Estimativa:** 4 hours  
**Impacto:** ⭐⭐⭐⭐ (evita memory leaks)

---

#### Passo 3️⃣ — Add Photo Limits & Paginação
**Objetivo:** Evitar payloads gigantes

**Ações:**
1. Fix `event_remote_data_source.dart`:
   ```dart
   // OLD:
   // final photos = await client.from('event_photos').select()...
   
   // NEW:
   final photoPagination = photo

sPaginated({
     required String eventId,
     required int limit,
     required int offset,
   }) async {
     return await client
       .from('event_photos')
       .select()
       .eq('event_id', eventId)
       .order('created_at', ascending: false)
       .range(offset, offset + limit - 1);
   }
   ```
2. Criar StateNotifier para UI:
   ```dart
   class EventPhotosManager extends StateNotifier<AsyncValue<List<Photo>>> {
     // loadMore() trigger
   }
   ```
3. Testar: evento com 1000 fotos mostra 50 primeiras, loadMore funciona

**Estimativa:** 3 hours  
**Impacto:** ⭐⭐⭐⭐ (evita OOM)

---

#### Passo 4️⃣ — Add Global Timeouts + Retry Logic
**Objetivo:** Robustez em rede instável

**Ações:**
1. Adicionar `retry` package ao pubspec.yaml
2. Criar `services/network_resilience_service.dart`:
   ```dart
   Future<T> withRetry<T>({
     required Future<T> Function() fn,
     int maxRetries = 3,
     Duration initialDelay = const Duration(milliseconds: 100),
   }) async {
     return retry(
       fn,
       maxAttempts: maxRetries,
       delayFactor: 2.0, // exponential backoff
       maxDelay: const Duration(seconds: 5),
       onRetry: (e) => logger.warn('Retry: $e'),
     );
   }
   ```
3. Usar em data_sources:
   ```dart
   final user = await withRetry(
     fn: () => client.from('users').select().single(),
     maxRetries: 3,
   );
   ```
4. Add timeout wrapper:
   ```dart
   future.timeout(const Duration(seconds: 10), onTimeout: () {
     throw TimeoutException('Network timeout');
   });
   ```

**Estimativa:** 3 hours  
**Impacto:** ⭐⭐⭐⭐

---

### **FASE 2: Importantes (P1) — Semana 2**

#### Passo 5️⃣ — Add Skeleton Screens
**Localização:** `lib/shared/components/skeletons/`

**Ações:**
1. Criar skeleton widgets:
   - `EventCardSkeleton`
   - `MemoryCardSkeleton`
   - `NotificationSkeleton`
2. Replace:
   ```dart
   // OLD:
   loading: () => CircularProgressIndicator(),
   
   // NEW:
   loading: () => ListView(
     children: List.generate(3, (_) => EventCardSkeleton()),
   ),
   ```
3. Test: Home mostra skeletons, depois real data

**Estimativa:** 2 hours  
**Impacto:** ⭐⭐⭐

---

#### Passo 6️⃣ — Debounce Search + Min 3 Chars
**Localização:** `home_search_page.dart`

**Ações:**
```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose((ref) async {
  final query = ref.watch(searchQueryProvider);
  
  if (query.length < 3) return [];
  
  // Debounce 500ms
  await Future.delayed(const Duration(milliseconds: 500));
  
  return dataSource.search(query);
});
```

**Estimativa:** 1 hour  
**Impacto:** ⭐⭐⭐

---

#### Passo 7️⃣ — Lazy Load Images
**Localização:** `shared/components/cards/`

**Ações:**
1. Install `visibility_detector` package
2. Wrap images:
   ```dart
   VisibilityDetector(
     key: Key(imageUrl),
     onVisibilityChanged: (visibilityInfo) {
       if (visibilityInfo.visibleFraction > 0.1) {
         // Load image
       }
     },
     child: Image.network(...),
   )
   ```

**Estimativa:** 2 hours  
**Impacto:** ⭐⭐

---

#### Passo 8️⃣ — Stale-While-Revalidate Pattern
**Localização:** `home_event_providers.dart`

**Ações:**
```dart
final homeEventsProvider = FutureProvider.autoDispose((ref) async {
  final box = Hive.box<HomeEvent>('homeEvents');
  final cacheValid = box.isNotEmpty && (DateTime.now().difference(lastUpdate) < Duration(minutes: 5));
  
  // Return cache immediately (stale)
  if (cacheValid) {
    return box.values.toList();
  }
  
  // But also revalidate in background
  unawaited(
    (await ref.watch(getFreshEventsProvider.future)).then((fresh) {
      // Update box
    })
  );
  
  return box.values.isEmpty ? fresh : box.values.toList();
});
```

**Estimativa:** 2 hours  
**Impacto:** ⭐⭐⭐

---

### **FASE 3: Melhorias (P2) — After**

#### Passo 9️⃣ — Guest List Paginação
**Localização:** `event_rsvps_provider.dart`

**Estimativa:** 1.5 hours

#### Passo 1️⃣0️⃣ — Add Logging & Metrics  
**Localização:** `services/analytics_service.dart`

```dart
logNetworkEvent(
  endpoint: 'home_events_view',
  duration: stopwatch.elapsed,
  statusCode: response.status,
  payloadSize: response.body.length,
)
```

**Estimativa:** 2 hours

---

## 📈 RESUMO ANTES/DEPOIS

| Métrica | Antes | Depois | Ganho |
|---------|-------|--------|-------|
| TTFB (Time to First Byte) | 2-4s | **0.5s** (cached) | ⭐⭐⭐⭐⭐ |
| Time to Interactive | 2-4s | **1s** | ⭐⭐⭐⭐ |
| Network Requests (App Launch) | 6-8 | **2** (1 check + 1 refetch) | ⭐⭐⭐ |
| Memory Leaks | High risk | Resolved | ⭐⭐⭐⭐ |
| Offline Support | ❌ | ✅ | ⭐⭐⭐⭐⭐ |
| Error Recovery | Auto timeout | Retry + fallback | ⭐⭐⭐⭐ |

---

## 🎬 CONCLUSÃO

**Diagnóstico:** App tem **boa arquitetura** (Clean Arch + Riverpod) mas **implementação incompleta**:
- ✅ Domain/Repo/DataSource pattern
- ✅ Paginação offset-based
- ✅ Riverpod autoDispose
- ❌ Sem DB local
- ❌ Sem request cancellation
- ❌ Sem timeouts
- ❌ Sem skeleton screens
- ❌ Sem offline-first

**Prioridade:** P0 (DB local + caching + cancellation) resolve 80% dos problemas de UX fluida.

**Timeline:** 7-10 dias para implementar FASE 1+2 (80% dos ganhos).
