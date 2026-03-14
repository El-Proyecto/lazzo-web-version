# Performance Optimization - Events Loading

**Data:** 22 de janeiro de 2026  
**Objetivo:** Otimizar carregamento de eventos na Home e Group Hub com paginação, infinite scroll e cache de avatars

---

## 📋 Resumo das Alterações

### 1. Group Hub - Infinite Scroll + Paginação
- Adicionar paginação na query (page size: 20-30 eventos)
- Implementar infinite scroll no Group Hub
- Carregar mais eventos ao chegar ao fim da lista

### 2. Cache de Signed URLs para Avatars
- Implementar cache em memória para signed URLs
- Batch processing: processar todos os avatars únicos de uma vez
- Reduzir chamadas redundantes ao storage (mesmas 5-10 pessoas)

### 3. Home - Eventos Limitados + "See All"
- Limitar Confirmed e Pending a 10 eventos cada
- Adicionar botão "See All" (só aparece se > 10)
- Criar página dedicada `EventsListPage` com infinite scroll

---

## 🎯 Fase 1: Cache de Signed URLs (Foundation)

**Prioridade:** Alta (afeta todas as queries)  
**Tempo estimado:** 1-2 horas

### 1.1. Criar Serviço de Cache de Avatars

**Novo arquivo:** `lib/services/avatar_cache_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cache service for avatar signed URLs
/// Prevents redundant storage calls for the same avatars
class AvatarCacheService {
  static final AvatarCacheService _instance = AvatarCacheService._internal();
  factory AvatarCacheService() => _instance;
  AvatarCacheService._internal();

  static const String _avatarBucketName = 'users-profile-pic';
  static const int _cacheExpirySeconds = 3000; // 50min (signed URLs valid for 1h)

  // Cache: storage_path -> (url, expiry_time)
  final Map<String, _CacheEntry> _cache = {};

  /// Get authenticated avatar URL with caching
  Future<String> getAvatarUrl(
    SupabaseClient client,
    String? storagePath,
  ) async {
    if (storagePath == null || storagePath.isEmpty) return '';

    // Already a full URL
    if (storagePath.startsWith('http://') || storagePath.startsWith('https://')) {
      return storagePath;
    }

    // Normalize path
    final normalizedPath = storagePath.startsWith('/') 
        ? storagePath.substring(1) 
        : storagePath;

    // Check cache
    final cached = _cache[normalizedPath];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    // Fetch from storage
    try {
      final url = await client.storage
          .from(_avatarBucketName)
          .createSignedUrl(normalizedPath, 3600);

      // Store in cache
      _cache[normalizedPath] = _CacheEntry(
        url: url,
        expiryTime: DateTime.now().add(Duration(seconds: _cacheExpirySeconds)),
      );

      return url;
    } catch (e) {
      return '';
    }
  }

  /// Batch process multiple avatar paths
  /// Returns map: storage_path -> signed_url
  Future<Map<String, String>> batchGetAvatarUrls(
    SupabaseClient client,
    List<String> storagePaths,
  ) async {
    final result = <String, String>{};
    final pathsToFetch = <String>[];

    // Check cache first
    for (final path in storagePaths) {
      if (path.isEmpty) continue;

      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      final cached = _cache[normalizedPath];

      if (cached != null && !cached.isExpired) {
        result[path] = cached.url;
      } else {
        pathsToFetch.add(normalizedPath);
      }
    }

    // Fetch uncached URLs in parallel
    if (pathsToFetch.isNotEmpty) {
      final futures = pathsToFetch.map((path) async {
        try {
          final url = await client.storage
              .from(_avatarBucketName)
              .createSignedUrl(path, 3600);

          _cache[path] = _CacheEntry(
            url: url,
            expiryTime: DateTime.now().add(Duration(seconds: _cacheExpirySeconds)),
          );

          return MapEntry(path, url);
        } catch (e) {
          return MapEntry(path, '');
        }
      });

      final fetchedUrls = await Future.wait(futures);
      for (final entry in fetchedUrls) {
        // Match original path (with or without leading slash)
        final originalPath = storagePaths.firstWhere(
          (p) => p == entry.key || p == '/${entry.key}',
          orElse: () => entry.key,
        );
        result[originalPath] = entry.value;
      }
    }

    return result;
  }

  /// Clear expired entries (call periodically)
  void clearExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Clear all cache (for testing/logout)
  void clearAll() {
    _cache.clear();
  }
}

class _CacheEntry {
  final String url;
  final DateTime expiryTime;

  _CacheEntry({required this.url, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
```

### 1.2. Atualizar Data Sources para Usar Cache

**Arquivos a modificar:**

1. `lib/features/home/data/data_sources/home_event_remote_data_source.dart`
2. `lib/features/group_hub/data/data_sources/group_event_data_source.dart`
3. Qualquer outro data source que processa avatars

**Padrão de implementação:**

```dart
import '../../../../services/avatar_cache_service.dart';

class HomeEventRemoteDataSource {
  final SupabaseClient client;
  final AvatarCacheService _avatarCache = AvatarCacheService();

  // ANTES: Processava um por um
  Future<void> _convertAvatarUrlsInUserArray(
      Map<String, dynamic> event, String arrayKey) async {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic> && user['avatar_url'] != null) {
        user['avatar_url'] = await _getAuthenticatedAvatarUrl(user['avatar_url']);
      }
    }
  }

  // DEPOIS: Batch processing
  Future<void> _batchConvertAvatarUrls(List<Map<String, dynamic>> events) async {
    // 1. Coletar todos os paths únicos
    final allPaths = <String>{};
    
    for (final event in events) {
      _collectAvatarPaths(event, 'going_users', allPaths);
      _collectAvatarPaths(event, 'not_going_users', allPaths);
      _collectAvatarPaths(event, 'no_response_users', allPaths);
    }

    // 2. Batch fetch todos os URLs de uma vez
    final urlMap = await _avatarCache.batchGetAvatarUrls(
      client,
      allPaths.toList(),
    );

    // 3. Aplicar URLs aos eventos
    for (final event in events) {
      _applyAvatarUrls(event, 'going_users', urlMap);
      _applyAvatarUrls(event, 'not_going_users', urlMap);
      _applyAvatarUrls(event, 'no_response_users', urlMap);
    }
  }

  void _collectAvatarPaths(
    Map<String, dynamic> event,
    String arrayKey,
    Set<String> paths,
  ) {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic> && user['avatar_url'] != null) {
        paths.add(user['avatar_url']);
      }
    }
  }

  void _applyAvatarUrls(
    Map<String, dynamic> event,
    String arrayKey,
    Map<String, String> urlMap,
  ) {
    final users = event[arrayKey] as List?;
    if (users == null) return;

    for (final user in users) {
      if (user is Map<String, dynamic> && user['avatar_url'] != null) {
        user['avatar_url'] = urlMap[user['avatar_url']] ?? '';
      }
    }
  }
}
```

---

## 🎯 Fase 2: Group Hub - Infinite Scroll

**Prioridade:** Média  
**Tempo estimado:** 2-3 horas

### 2.1. Adicionar Paginação ao Data Source

**Arquivo:** `lib/features/group_hub/data/data_sources/group_event_data_source.dart`

**Alterações:**

```dart
abstract class GroupEventDataSource {
  /// Get paginated events for a specific group
  Future<List<Map<String, dynamic>>> getGroupEvents(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  });

  /// Get total count of non-ended events in group
  Future<int> getGroupEventsCount(String groupId);
}

class SupabaseGroupEventDataSource implements GroupEventDataSource {
  // ... existing code ...

  @override
  Future<List<Map<String, dynamic>>> getGroupEvents(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('group_hub_events_view')
          .select()
          .eq('group_id', groupId)
          .neq('computed_status', 'ended')
          .order('priority', ascending: false)
          .order('start_datetime', ascending: true)
          .range(offset, offset + pageSize - 1); // ✅ Paginação

      final events = List<Map<String, dynamic>>.from(response as List);

      // ✅ Batch processing de avatars
      await _batchConvertAvatarUrls(events);

      return events;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<int> getGroupEventsCount(String groupId) async {
    try {
      final response = await _client
          .from('group_hub_events_view')
          .select('event_id', const FetchOptions(count: CountOption.exact))
          .eq('group_id', groupId)
          .neq('computed_status', 'ended');

      return response.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ✅ Implementar batch processing aqui (copiar do exemplo acima)
  Future<void> _batchConvertAvatarUrls(List<Map<String, dynamic>> events) async {
    // ... implementação igual ao exemplo da Fase 1
  }
}
```

### 2.2. Atualizar Repository

**Arquivo:** `lib/features/group_hub/domain/repositories/group_event_repository.dart`

```dart
abstract class GroupEventRepository {
  Future<List<GroupEvent>> getGroupEvents(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  });

  Future<int> getGroupEventsCount(String groupId);
}
```

**Arquivo:** `lib/features/group_hub/data/repositories/group_event_repository_impl.dart`

```dart
class GroupEventRepositoryImpl implements GroupEventRepository {
  // ... existing code ...

  @override
  Future<List<GroupEvent>> getGroupEvents(
    String groupId, {
    int pageSize = 20,
    int offset = 0,
  }) async {
    final data = await dataSource.getGroupEvents(
      groupId,
      pageSize: pageSize,
      offset: offset,
    );
    
    return data.map((e) => GroupEventModel.fromMap(e).toEntity()).toList();
  }

  @override
  Future<int> getGroupEventsCount(String groupId) {
    return dataSource.getGroupEventsCount(groupId);
  }
}
```

### 2.3. Criar Provider Paginado

**Arquivo:** `lib/features/group_hub/presentation/providers/group_event_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paginated events state
class PaginatedEventsState {
  final List<GroupEvent> events;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PaginatedEventsState({
    this.events = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PaginatedEventsState copyWith({
    List<GroupEvent>? events,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return PaginatedEventsState(
      events: events ?? this.events,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Paginated events controller
class PaginatedGroupEventsController
    extends StateNotifier<PaginatedEventsState> {
  final GroupEventRepository _repository;
  final String _groupId;
  static const int _pageSize = 20;

  PaginatedGroupEventsController(this._repository, this._groupId)
      : super(const PaginatedEventsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _repository.getGroupEvents(
        _groupId,
        pageSize: _pageSize,
        offset: 0,
      );

      state = state.copyWith(
        events: events,
        hasMore: events.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final newEvents = await _repository.getGroupEvents(
        _groupId,
        pageSize: _pageSize,
        offset: state.events.length,
      );

      state = state.copyWith(
        events: [...state.events, ...newEvents],
        hasMore: newEvents.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

/// Provider
final paginatedGroupEventsProvider = StateNotifierProvider.family<
    PaginatedGroupEventsController,
    PaginatedEventsState,
    String>((ref, groupId) {
  return PaginatedGroupEventsController(
    ref.watch(groupEventRepositoryProvider),
    groupId,
  );
});
```

### 2.4. Atualizar UI do Group Hub

**Arquivo:** `lib/features/group_hub/presentation/pages/group_hub_page.dart`

**Substituir ListView por ListView.builder com scroll detection:**

```dart
class _EventsListSection extends ConsumerStatefulWidget {
  final String groupId;
  
  const _EventsListSection({required this.groupId});

  @override
  ConsumerState<_EventsListSection> createState() => _EventsListSectionState();
}

class _EventsListSectionState extends ConsumerState<_EventsListSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      ref.read(paginatedGroupEventsProvider(widget.groupId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedGroupEventsProvider(widget.groupId));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(paginatedGroupEventsProvider(widget.groupId).notifier)
          .refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.events.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at bottom
          if (index == state.events.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final event = state.events[index];
          return GroupEventCard(event: event);
        },
      ),
    );
  }
}
```

---

## 🎯 Fase 3: Home - Eventos Limitados + "See All"

**Prioridade:** Alta  
**Tempo estimado:** 3-4 horas

### 3.1. Atualizar Data Source - Reduzir Limite

**Arquivo:** `lib/features/home/data/data_sources/home_event_remote_data_source.dart`

**Alterações:**

```dart
// Linha 113: Confirmed events
.limit(10); // ✅ CHANGED: 20 → 10

// Linha 174: Pending events  
.limit(10); // ✅ CHANGED: 20 → 10

// ✅ ADICIONAR: Método para contar eventos
Future<int> getConfirmedEventsCount(String userId) async {
  try {
    final response = await client
        .from(_eventsView)
        .select('event_id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId)
        .eq('event_status', 'confirmed')
        .eq('user_rsvp', 'yes');

    return response.count ?? 0;
  } catch (e) {
    return 0;
  }
}

Future<int> getPendingEventsCount(String userId) async {
  try {
    final response = await client
        .from(_eventsView)
        .select('event_id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId)
        .eq('event_status', 'pending');

    return response.count ?? 0;
  } catch (e) {
    return 0;
  }
}
```

### 3.2. Criar EventsListPage (Página Dedicada)

**Novo arquivo:** `lib/features/home/presentation/pages/events_list_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/home_event.dart';

/// Full-screen list of events with infinite scroll
/// Used for "See All" from Home page
class EventsListPage extends ConsumerStatefulWidget {
  final EventListType type;

  const EventsListPage({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

enum EventListType {
  confirmed,
  pending,
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more
      final provider = widget.type == EventListType.confirmed
          ? paginatedConfirmedEventsProvider
          : paginatedPendingEventsProvider;
      
      ref.read(provider.notifier).loadMore();
    }
  }

  String get _title {
    return widget.type == EventListType.confirmed
        ? 'Confirmed Events'
        : 'Pending Events';
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.type == EventListType.confirmed
        ? paginatedConfirmedEventsProvider
        : paginatedPendingEventsProvider;

    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: BrandColors.bg2,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(provider.notifier).refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(Pads.sectionH),
                    itemCount: state.events.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.events.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final event = state.events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Gaps.md),
                        child: HomeEventCard(event: event),
                      );
                    },
                  ),
                ),
    );
  }
}
```

### 3.3. Criar Providers Paginados

**Arquivo:** `lib/features/home/presentation/providers/home_event_providers.dart`

```dart
// ✅ ADICIONAR: State class (mesma do Group Hub)
class PaginatedEventsState {
  // ... copiar da Fase 2
}

// ✅ ADICIONAR: Controllers para Confirmed e Pending
class PaginatedConfirmedEventsController
    extends StateNotifier<PaginatedEventsState> {
  final HomeEventRemoteDataSource _dataSource;
  final String _userId;
  static const int _pageSize = 20;

  PaginatedConfirmedEventsController(this._dataSource, this._userId)
      : super(const PaginatedEventsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ✅ Criar novo método no data source com paginação
      final events = await _dataSource.fetchConfirmedEventsPaginated(
        _userId,
        limit: _pageSize,
        offset: 0,
      );

      state = state.copyWith(
        events: events,
        hasMore: events.length >= _pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final newEvents = await _dataSource.fetchConfirmedEventsPaginated(
        _userId,
        limit: _pageSize,
        offset: state.events.length,
      );

      state = state.copyWith(
        events: [...state.events, ...newEvents],
        hasMore: newEvents.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitial();
}

// ✅ Providers
final paginatedConfirmedEventsProvider = StateNotifierProvider<
    PaginatedConfirmedEventsController,
    PaginatedEventsState>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  return PaginatedConfirmedEventsController(
    ref.watch(homeEventDataSourceProvider),
    userId,
  );
});

final paginatedPendingEventsProvider = StateNotifierProvider<
    PaginatedPendingEventsController,
    PaginatedEventsState>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  return PaginatedPendingEventsController(
    ref.watch(homeEventDataSourceProvider),
    userId,
  );
});

// ✅ Providers para contar eventos
final confirmedEventsCountProvider = FutureProvider<int>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final dataSource = ref.watch(homeEventDataSourceProvider);
  return dataSource.getConfirmedEventsCount(userId);
});

final pendingEventsCountProvider = FutureProvider<int>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final dataSource = ref.watch(homeEventDataSourceProvider);
  return dataSource.getPendingEventsCount(userId);
});
```

### 3.4. Adicionar Método Paginado ao Data Source

**Arquivo:** `lib/features/home/data/data_sources/home_event_remote_data_source.dart`

```dart
/// Fetch confirmed events with pagination
Future<List<HomeEventEntity>> fetchConfirmedEventsPaginated(
  String userId, {
  required int limit,
  required int offset,
}) async {
  try {
    final response = await client
        .from(_eventsView)
        .select('''
          event_id, event_name, emoji,
          group_id, group_name,
          start_datetime, end_datetime,
          location_name, event_status,
          user_rsvp, voted_at,
          going_count, going_users,
          not_going_users, no_response_users,
          participants_total, voters_total
        ''')
        .eq('user_id', userId)
        .eq('event_status', 'confirmed')
        .eq('user_rsvp', 'yes')
        .range(offset, offset + limit - 1); // ✅ Paginação

    final data = response as List<dynamic>;

    // ✅ Batch processing de avatars
    final events = await _batchProcessEvents(data, userId);

    return events;
  } catch (e) {
    return [];
  }
}

/// Fetch pending events with pagination
Future<List<HomeEventEntity>> fetchPendingEventsPaginated(
  String userId, {
  required int limit,
  required int offset,
}) async {
  // ✅ Implementação similar ao confirmed
}

/// Helper: batch process events (DRY)
Future<List<HomeEventEntity>> _batchProcessEvents(
  List<dynamic> data,
  String userId,
) async {
  if (data.isEmpty) return [];

  final eventsFutures = data.map((e) => homeEventFromMap(
        e as Map<String, dynamic>,
        onStatusMismatch: (eventId, newStatus) {
          updateEventStatus(eventId, newStatus).catchError((error) {
            return false;
          });
        },
        currentUserId: userId,
        supabaseClient: client,
      ));

  return await Future.wait(eventsFutures);
}
```

### 3.5. Atualizar Home Page - Adicionar Botão "See All"

**Arquivo:** `lib/features/home/presentation/pages/home_page.dart`

```dart
// ✅ Confirmed Events Section
Widget _buildConfirmedEventsSection() {
  final confirmedAsync = ref.watch(confirmedEventsProvider);
  final countAsync = ref.watch(confirmedEventsCountProvider);

  return confirmedAsync.when(
    data: (events) {
      if (events.isEmpty) return const SizedBox.shrink();

      final totalCount = countAsync.maybeWhen(
        data: (count) => count,
        orElse: () => events.length,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com "See All"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirmed',
                  style: AppText.titleMedium,
                ),
                if (totalCount > 10)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.eventsList,
                        arguments: EventListType.confirmed,
                      );
                    },
                    child: Text(
                      'See All ($totalCount)',
                      style: AppText.labelMedium.copyWith(
                        color: BrandColors.planning,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.sm),
          // Lista (max 10)
          ...events.take(10).map((event) => HomeEventCard(event: event)),
        ],
      );
    },
    loading: () => const CircularProgressIndicator(),
    error: (error, stack) => Text('Error: $error'),
  );
}

// ✅ Pending Events Section (implementação similar)
Widget _buildPendingEventsSection() {
  // ... similar ao confirmed
}
```

### 3.6. Adicionar Rota

**Arquivo:** `lib/routes/app_router.dart`

```dart
class AppRouter {
  // ... existing routes ...
  static const String eventsList = '/events-list';
}

// No onGenerateRoute:
case AppRouter.eventsList:
  final type = settings.arguments as EventListType;
  return MaterialPageRoute(
    builder: (_) => EventsListPage(type: type),
  );
```

---

## 🎯 Fase 4: Testes & Validação

### 4.1. Testes Manuais

**Checklist:**

- [ ] Group Hub carrega primeiros 20 eventos
- [ ] Scroll até ao fim carrega mais 20 eventos
- [ ] Infinite scroll funciona sem duplicações
- [ ] Pull-to-refresh atualiza lista corretamente
- [ ] Cache de avatars reduz tempo de carregamento
- [ ] Mesmos avatars não fazem requests redundantes
- [ ] Home mostra max 10 confirmed e 10 pending
- [ ] Botão "See All" só aparece quando > 10 eventos
- [ ] EventsListPage abre corretamente
- [ ] EventsListPage tem infinite scroll funcional
- [ ] Contador "(X)" mostra número correto de eventos

### 4.2. Métricas de Performance

**Antes vs Depois:**

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| Home: Eventos carregados | 10+20+20+20 = 70 | 10+10+10+20 = 50 | -29% |
| Home: Tempo inicial | ~3-5s | ~1-2s | -60% |
| Group Hub: Eventos iniciais | Todos (100+) | 20 | -80%+ |
| Group Hub: Tempo inicial | ~5-10s | ~1-2s | -75% |
| Avatar requests (10 users) | 10 x N eventos | 10 total (cache) | -90%+ |

### 4.3. Casos Edge a Testar

1. **Sem eventos:** lista vazia não crashar
2. **Exatamente 10 eventos:** botão "See All" não aparece
3. **11 eventos:** botão "See All" aparece com "(11)"
4. **Cache expirado:** renovar signed URLs automaticamente
5. **Offline:** mostrar erro gracefully, retry ao voltar online
6. **Scroll rápido:** não carregar múltiplas páginas simultaneamente

---

## 📝 Ordem de Implementação Recomendada

### Sprint 1: Foundation (1-2 dias)
1. ✅ Criar `AvatarCacheService`
2. ✅ Atualizar Home data source com batch processing
3. ✅ Atualizar Group Hub data source com batch processing
4. ✅ Testar cache isoladamente

### Sprint 2: Group Hub Infinite Scroll (1-2 dias)
1. ✅ Adicionar paginação ao data source
2. ✅ Criar controller paginado
3. ✅ Atualizar UI com scroll detection
4. ✅ Testar infinite scroll

### Sprint 3: Home "See All" (2-3 dias)
1. ✅ Reduzir limites para 10
2. ✅ Adicionar métodos de contagem
3. ✅ Criar `EventsListPage`
4. ✅ Criar providers paginados
5. ✅ Adicionar botão "See All" na Home
6. ✅ Adicionar rota

### Sprint 4: Polish & Testing (1 dia)
1. ✅ Testes manuais completos
2. ✅ Medir métricas de performance
3. ✅ Ajustes de UI/UX
4. ✅ Documentação final

---

## 🚀 Resultados Esperados

### Performance
- ⚡ Home carrega 40% mais rápido (menos eventos processados)
- ⚡ Group Hub carrega 75% mais rápido (paginação)
- ⚡ Avatars 90% mais rápidos (cache + batch)

### UX
- 📱 Home limpa e focada (max 10 de cada tipo)
- 📱 "See All" para explorar todos os eventos
- 📱 Infinite scroll suave no Group Hub
- 📱 Pull-to-refresh em todos os lugares

### Scalability
- 📈 Suporta centenas de eventos sem lag
- 📈 Cache de avatars escala para qualquer número de participantes
- 📈 Paginação permite crescimento ilimitado

---

## 📚 Referências

- [Supabase Pagination](https://supabase.com/docs/guides/api/pagination)
- [Flutter Infinite Scroll Pattern](https://docs.flutter.dev/cookbook/lists/long-lists)
- [Riverpod State Management](https://riverpod.dev/docs/concepts/reading)
- .agents/agents.md - Architecture guidelines

---

**Status:** ✅ Pronto para implementação  
**Próximo passo:** Revisar guião e iniciar Sprint 1
