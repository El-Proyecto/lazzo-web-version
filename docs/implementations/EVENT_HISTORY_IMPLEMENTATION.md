# Event History — P2 Implementation Guide

**Feature:** Bottom sheet para mostrar histórico de eventos do utilizador na página Create Event  
**Objective:** Permitir que utilizadores reutilizem eventos anteriores como templates (nome, emoji, hora, localização)  
**Architecture:** Clean Architecture (Presentation/Domain/Data layers)  
**No new tables required:** Query existing `events` table

---

## 📋 Overview

Este guião implementa a funcionalidade de histórico de eventos na página Create Event, permitindo que o utilizador:
- Visualize seus últimos eventos criados (independente do grupo)
- Selecione um evento anterior para usar como template
- Carregue automaticamente nome, emoji, hora aproximada e localização

**Status atual:**
- ✅ UI já implementada (`EventHistoryBottomSheet`, `EventHistoryItem`)
- ✅ Mock data funcionando (`_getMockEventHistory()`)
- ❌ Falta: Data layer com queries reais ao Supabase

---

## Part 1: Database Schema Changes

### ⚠️ No new tables needed!

O histórico de eventos usa a tabela `events` existente com query simples:

```sql
-- Query para buscar últimos eventos do utilizador (qualquer grupo)
SELECT 
  id,
  name,
  emoji,
  start_datetime,
  location_id,
  group_id,
  created_at
FROM events
WHERE created_by = $userId
  AND status IN ('confirmed', 'living', 'recap', 'ended')  -- Apenas eventos concluídos
  AND start_datetime IS NOT NULL                           -- Apenas eventos com data definida
ORDER BY start_datetime DESC
LIMIT 10;
```

### Database Verification Checklist

**Antes de implementar, verificar no Supabase Dashboard:**

- [ ] **Indexes existentes:**
  - `idx_events_created_by` — Index em `created_by` (já deve existir)
  - `idx_events_start_datetime` — Index em `start_datetime` (verificar se existe)
  
- [ ] **RLS Policies:**
  - Utilizador deve poder ler eventos que criou (`created_by = auth.uid()`)
  - Verificar política `SELECT` na tabela `events`

- [ ] **Test Query no SQL Editor:**
  ```sql
  -- Substituir 'YOUR_USER_ID' com UUID real de um utilizador de teste
  SELECT 
    id,
    name,
    emoji,
    start_datetime,
    location_id,
    group_id,
    created_at
  FROM events
  WHERE created_by = 'YOUR_USER_ID'
    AND status IN ('confirmed', 'living', 'recap', 'ended')
    AND start_datetime IS NOT NULL
  ORDER BY start_datetime DESC
  LIMIT 10;
  ```

- [ ] **Test Index Usage (EXPLAIN ANALYZE):**
  ```sql
  -- Verificar se query usa indexes eficientemente
  EXPLAIN ANALYZE
  SELECT 
    id,
    name,
    emoji,
    start_datetime,
    location_id,
    group_id,
    created_at
  FROM events
  WHERE created_by = 'YOUR_USER_ID'
    AND status IN ('confirmed', 'living', 'recap', 'ended')
    AND start_datetime IS NOT NULL
  ORDER BY start_datetime DESC
  LIMIT 10;
  
  -- Expected: "Index Scan using idx_events_history_query" or similar
  -- Red flag: "Seq Scan" (sequential scan = no index used)
  ```

- [ ] **Check Existing Indexes:**
  ```sql
  -- Listar todos os indexes na tabela events
  SELECT 
    indexname,
    indexdef
  FROM pg_indexes
  WHERE tablename = 'events'
  ORDER BY indexname;
  
  -- Procurar por:
  -- - idx_events_created_by
  -- - idx_events_start_datetime
  -- - idx_events_history_query (se criar o composto)
  ```

- [ ] **Test RLS Policy (como utilizador autenticado):**
  ```sql
  -- 1. Criar evento de teste (se não existir)
  INSERT INTO events (
    name,
    emoji,
    group_id,
    created_by,
    status,
    start_datetime
  ) VALUES (
    'Test Event History',
    '🧪',
    (SELECT id FROM groups WHERE created_by = auth.uid() LIMIT 1),
    auth.uid(),
    'ended',
    NOW() - INTERVAL '7 days'
  )
  RETURNING id, name, status;
  
  -- 2. Verificar se consegue ler próprios eventos
  SELECT COUNT(*) as my_events_count
  FROM events
  WHERE created_by = auth.uid();
  -- Expected: número > 0 se tiver eventos
  
  -- 3. Tentar ler eventos de outro utilizador (deve falhar/retornar 0)
  SELECT COUNT(*) as other_events_count
  FROM events
  WHERE created_by != auth.uid();
  -- Expected: 0 (RLS deve bloquear)
  ```

### Performance Optimization (Se necessário)

**Se não existir index em `start_datetime`:**

```sql
-- Criar index composto para otimizar query de histórico
CREATE INDEX IF NOT EXISTS idx_events_history_query 
ON events (created_by, start_datetime DESC)
WHERE status IN ('confirmed', 'living', 'recap', 'ended') 
  AND start_datetime IS NOT NULL;
```

**Justificativa:**
- Index composto otimiza query com `WHERE created_by = X ORDER BY start_datetime DESC`
- Index parcial (partial index) reduz tamanho indexando apenas eventos relevantes
- `DESC` no index alinha com `ORDER BY` da query (scan mais eficiente)

**Verificar criação do index:**
```sql
-- Confirmar que index foi criado
SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE indexname = 'idx_events_history_query';

-- Verificar tamanho do index
SELECT 
  pg_size_pretty(pg_relation_size('idx_events_history_query')) as index_size;
```

---

## Part 2: Code Implementation Tasks

### 2.1 Domain Layer

#### 2.1.1 Create EventHistory Entity

**File:** `lib/features/create_event/domain/entities/event_history.dart`

```dart
/// Event history entity for event template reuse
/// Minimal fields needed to populate create event form
class EventHistory {
  final String id;
  final String name;
  final String emoji;
  final DateTime startDateTime;
  final String? locationId;
  final String? locationName;      // Denormalized for performance
  final String? locationAddress;   // Denormalized for performance
  final double? latitude;          // Denormalized for performance
  final double? longitude;         // Denormalized for performance
  final String groupId;
  final DateTime createdAt;

  const EventHistory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.startDateTime,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.groupId,
    required this.createdAt,
  });

  @override
  String toString() {
    return 'EventHistory(id: $id, name: $name, emoji: $emoji, startDateTime: $startDateTime, locationName: $locationName, groupId: $groupId)';
  }
}
```

**Why separate entity from `Event`?**
- Event history has different purpose (template reuse)
- Needs denormalized location data for performance (avoid JOIN)
- Lighter entity (no full event details needed)

---

#### 2.1.2 Update Event Repository Interface

**File:** `lib/features/create_event/domain/repositories/event_repository.dart`

**Add method:**

```dart
/// Get user's recent events for template reuse
/// Returns events ordered by start_datetime DESC
/// Independent of group (shows all user's events)
Future<List<EventHistory>> getUserEventHistory({
  required String userId,
  int limit = 10,
});
```

**Method signature rationale:**
- `userId` explicit (no implicit auth in domain)
- `limit` with default (pagination ready)
- Returns `EventHistory` (not full `Event`)

---

#### 2.1.3 Create GetUserEventHistory Use Case

**File:** `lib/features/create_event/domain/usecases/get_user_event_history.dart`

```dart
import '../entities/event_history.dart';
import '../repositories/event_repository.dart';

/// Use case: Get user's event history for template reuse
/// Returns recent events ordered by date (most recent first)
class GetUserEventHistory {
  final EventRepository repository;

  const GetUserEventHistory(this.repository);

  Future<List<EventHistory>> call({
    required String userId,
    int limit = 10,
  }) async {
    return repository.getUserEventHistory(
      userId: userId,
      limit: limit,
    );
  }
}
```

**Why this use case?**
- Single responsibility: fetch event history
- Can add business logic later (e.g., filter by frequency)
- Keeps presentation layer clean

---

### 2.2 Data Layer

#### 2.2.1 Create EventHistory Model (DTO)

**File:** `lib/features/create_event/data/models/event_history_model.dart`

```dart
import '../../domain/entities/event_history.dart';

/// DTO for event history data from Supabase
/// Maps JSON from events + locations tables to EventHistory entity
class EventHistoryModel {
  final String id;
  final String name;
  final String emoji;
  final DateTime startDateTime;
  final String? locationId;
  final String? locationName;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final String groupId;
  final DateTime createdAt;

  const EventHistoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.startDateTime,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.groupId,
    required this.createdAt,
  });

  /// Parse from Supabase JSON row
  /// Handles joined location data from LEFT JOIN
  factory EventHistoryModel.fromJson(Map<String, dynamic> json) {
    // Parse location data if present (from JOIN)
    final locationData = json['locations'] as Map<String, dynamic>?;
    
    return EventHistoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      startDateTime: DateTime.parse(json['start_datetime'] as String),
      locationId: json['location_id'] as String?,
      locationName: locationData?['display_name'] as String?,
      locationAddress: locationData?['formatted_address'] as String?,
      latitude: locationData?['latitude'] as double?,
      longitude: locationData?['longitude'] as double?,
      groupId: json['group_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to domain entity
  EventHistory toEntity() {
    return EventHistory(
      id: id,
      name: name,
      emoji: emoji,
      startDateTime: startDateTime,
      locationId: locationId,
      locationName: locationName,
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
      groupId: groupId,
      createdAt: createdAt,
    );
  }

  /// Convert from domain entity (rarely used for history)
  factory EventHistoryModel.fromEntity(EventHistory entity) {
    return EventHistoryModel(
      id: entity.id,
      name: entity.name,
      emoji: entity.emoji,
      startDateTime: entity.startDateTime,
      locationId: entity.locationId,
      locationName: entity.locationName,
      locationAddress: entity.locationAddress,
      latitude: entity.latitude,
      longitude: entity.longitude,
      groupId: entity.groupId,
      createdAt: entity.createdAt,
    );
  }
}
```

**Key parsing decisions:**
- Handles nested `locations` object from JOIN
- Converts ISO 8601 strings to DateTime
- Null-safe parsing for optional location data

---

#### 2.2.2 Add Method to Event Remote Data Source

**File:** `lib/features/create_event/data/data_sources/event_remote_data_source.dart`

**Add method:**

```dart
/// Get user's recent events for history
/// Joins with locations table to get denormalized location data
Future<List<Map<String, dynamic>>> getUserEventHistory({
  required String userId,
  int limit = 10,
}) async {
  try {
    final response = await _client
        .from('events')
        .select('''
          id,
          name,
          emoji,
          start_datetime,
          location_id,
          group_id,
          created_at,
          locations (
            display_name,
            formatted_address,
            latitude,
            longitude
          )
        ''')
        .eq('created_by', userId)
        .inFilter('status', ['confirmed', 'living', 'recap', 'ended'])
        .not('start_datetime', 'is', null)
        .order('start_datetime', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    throw Exception('Failed to fetch event history: $e');
  }
}
```

**Query breakdown:**
- `select()` with nested relation (`locations (...)`) — single query with JOIN
- `eq('created_by', userId)` — RLS + filter by user
- `inFilter('status', [...])` — only completed events
- `not('start_datetime', 'is', null)` — exclude events without date
- `order('start_datetime', ascending: false)` — most recent first
- `limit(limit)` — pagination ready

**Performance notes:**
- Single query (no N+1 problem)
- Uses indexes on `created_by` and `start_datetime`
- LEFT JOIN on `locations` (null-safe if location deleted)

---

#### 2.2.3 Update Event Repository Implementation

**File:** `lib/features/create_event/data/repositories/event_repository_impl.dart`

**Add method:**

```dart
@override
Future<List<EventHistory>> getUserEventHistory({
  required String userId,
  int limit = 10,
}) async {
  try {
    final dataList = await dataSource.getUserEventHistory(
      userId: userId,
      limit: limit,
    );

    return dataList
        .map((json) => EventHistoryModel.fromJson(json).toEntity())
        .toList();
  } catch (e) {
    throw Exception('Repository: Failed to get event history: $e');
  }
}
```

**Error handling:**
- Wraps data source exceptions
- Provides context ("Repository:")
- Preserves original error message

---

#### 2.2.4 Update Fake Repository (for P1 testing)

**File:** `lib/features/create_event/data/fakes/fake_event_repository.dart`

**Add method:**

```dart
@override
Future<List<EventHistory>> getUserEventHistory({
  required String userId,
  int limit = 10,
}) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 500));

  // Return mock event history
  return [
    EventHistory(
      id: 'fake-history-1',
      name: 'Baza ao Rio',
      emoji: '🍖',
      startDateTime: DateTime.now().subtract(const Duration(days: 7, hours: 4, minutes: 30)),
      locationId: 'fake-loc-1',
      locationName: 'Tascardoso',
      locationAddress: 'Rua da Rosa 123, Lisboa',
      latitude: 38.7143,
      longitude: -9.1459,
      groupId: 'fake-group-1',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    EventHistory(
      id: 'fake-history-2',
      name: 'Futebol',
      emoji: '⚽',
      startDateTime: DateTime.now().subtract(const Duration(days: 14, hours: 6)),
      locationId: 'fake-loc-2',
      locationName: 'Campo do Jamor',
      locationAddress: 'Estádio Nacional, Oeiras',
      latitude: 38.7023,
      longitude: -9.2103,
      groupId: 'fake-group-1',
      createdAt: DateTime.now().subtract(const Duration(days: 21)),
    ),
    EventHistory(
      id: 'fake-history-3',
      name: 'Cinema Night',
      emoji: '🎬',
      startDateTime: DateTime.now().subtract(const Duration(days: 21, hours: 3)),
      locationId: 'fake-loc-3',
      locationName: 'Cinemas NOS Amoreiras',
      locationAddress: 'Avenida Eng. Duarte Pacheco, Lisboa',
      latitude: 38.7252,
      longitude: -9.1621,
      groupId: 'fake-group-2',
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
  ].take(limit).toList();
}
```

**Fake data quality:**
- Realistic Portuguese locations
- Varied times and dates
- Matches production data structure

---

### 2.3 Presentation Layer

#### 2.3.1 Create Event History Provider

**File:** `lib/features/create_event/presentation/providers/event_history_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event_history.dart';
import '../../domain/usecases/get_user_event_history.dart';
import 'event_providers.dart';

/// Provider for user event history
/// Fetches recent events for template reuse
final eventHistoryProvider = FutureProvider.autoDispose
    .family<List<EventHistory>, String>((ref, userId) async {
  final useCase = GetUserEventHistory(ref.read(eventRepositoryProvider));
  
  return useCase(userId: userId, limit: 10);
});
```

**Provider design:**
- `FutureProvider` for async data
- `.autoDispose` to free memory when not used
- `.family<..., String>` parameterized by userId
- Limit hardcoded to 10 (sufficient for UI)

---

#### 2.3.2 Update Create Event Page (Remove Mock)

**File:** `lib/features/create_event/presentation/pages/create_event_page.dart`

**Changes required:**

1. **Add imports:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/event_history_provider.dart';
import '../../domain/entities/event_history.dart';
import '../../../../services/supabase_service.dart';
```

2. **Convert StatefulWidget to ConsumerStatefulWidget:**
```dart
// Before
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  // ...
}

// After
class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  // ...
}
```

3. **Replace `_showEventHistory()` method:**
```dart
// REMOVE OLD METHOD:
void _showEventHistory() {
  EventHistoryBottomSheet.show(
    context: context,
    events: _getMockEventHistory(),
    onEventSelected: _loadEventFromHistory,
  );
}

// REPLACE WITH:
void _showEventHistory() {
  final userId = SupabaseService.client.auth.currentUser?.id;
  
  if (userId == null) {
    // User not authenticated (should not happen, but handle gracefully)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not authenticated')),
    );
    return;
  }

  // Watch event history provider
  final eventHistoryAsync = ref.watch(eventHistoryProvider(userId));

  eventHistoryAsync.when(
    data: (history) {
      // Convert EventHistory entities to EventHistoryItem (presentation model)
      final historyItems = history.map((event) {
        TimeOfDay? timeOfDay;
        if (event.startDateTime != null) {
          timeOfDay = TimeOfDay(
            hour: event.startDateTime.hour,
            minute: event.startDateTime.minute,
          );
        }

        return EventHistoryItem(
          id: event.id,
          name: event.name,
          emoji: event.emoji,
          lastDate: event.startDateTime,
          lastTime: timeOfDay,
          location: event.locationName,
          groupId: event.groupId,
        );
      }).toList();

      EventHistoryBottomSheet.show(
        context: context,
        events: historyItems,
        onEventSelected: _loadEventFromHistory,
      );
    },
    loading: () {
      // Show loading indicator while fetching
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: BrandColors.planning),
        ),
      );
    },
    error: (error, stackTrace) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load event history: $error'),
          backgroundColor: BrandColors.cantVote,
        ),
      );
    },
  );
}
```

4. **Remove `_getMockEventHistory()` method entirely** (lines 819-851)

**Key changes explained:**
- Get `userId` from Supabase auth
- Use `ref.watch()` to consume provider
- Handle `AsyncValue` states (data/loading/error)
- Map `EventHistory` → `EventHistoryItem` (domain → presentation)
- Extract `TimeOfDay` from `DateTime`

---

#### 2.3.3 Update Event History Widget (Domain Entity Support)

**File:** `lib/features/create_event/presentation/widgets/event_history_dialog.dart`

**No changes required!** Widget already uses `EventHistoryItem` presentation model, which is populated from domain entities in the page.

---

### 2.4 Dependency Injection

**File:** `lib/main.dart`

**Verify/Add provider override:**

```dart
// In ProviderScope overrides list
eventRepositoryProvider.overrideWithValue(
  EventRepositoryImpl(
    dataSource: EventRemoteDataSource(SupabaseService.client),
  ),
),
```

**Check if exists:** If `eventRepositoryProvider` already has real implementation override, no changes needed.

---

## Part 3: Testing Strategy

### 3.1 Unit Tests (Data Layer)

**File:** `test/unit_tests/features/create_event/data/models/event_history_model_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/data/models/event_history_model.dart';

void main() {
  group('EventHistoryModel', () {
    test('fromJson parses valid data with location', () {
      final json = {
        'id': 'event-123',
        'name': 'Test Event',
        'emoji': '🎉',
        'start_datetime': '2024-12-15T19:30:00Z',
        'location_id': 'loc-123',
        'group_id': 'group-123',
        'created_at': '2024-12-01T10:00:00Z',
        'locations': {
          'display_name': 'Test Venue',
          'formatted_address': 'Test Address, Lisboa',
          'latitude': 38.7143,
          'longitude': -9.1459,
        },
      };

      final model = EventHistoryModel.fromJson(json);

      expect(model.id, 'event-123');
      expect(model.name, 'Test Event');
      expect(model.emoji, '🎉');
      expect(model.locationName, 'Test Venue');
      expect(model.latitude, 38.7143);
    });

    test('fromJson handles null location', () {
      final json = {
        'id': 'event-123',
        'name': 'Test Event',
        'emoji': '🎉',
        'start_datetime': '2024-12-15T19:30:00Z',
        'location_id': null,
        'group_id': 'group-123',
        'created_at': '2024-12-01T10:00:00Z',
        'locations': null,
      };

      final model = EventHistoryModel.fromJson(json);

      expect(model.locationId, isNull);
      expect(model.locationName, isNull);
      expect(model.latitude, isNull);
    });

    test('toEntity converts to domain entity', () {
      final model = EventHistoryModel(
        id: 'event-123',
        name: 'Test Event',
        emoji: '🎉',
        startDateTime: DateTime(2024, 12, 15, 19, 30),
        locationId: 'loc-123',
        locationName: 'Test Venue',
        locationAddress: 'Test Address',
        latitude: 38.7143,
        longitude: -9.1459,
        groupId: 'group-123',
        createdAt: DateTime(2024, 12, 1, 10, 0),
      );

      final entity = model.toEntity();

      expect(entity.id, 'event-123');
      expect(entity.name, 'Test Event');
      expect(entity.locationName, 'Test Venue');
    });
  });
}
```

---

### 3.2 Integration Test (E2E Flow)

**File:** `test/integration_tests/event_history_flow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazzo/features/create_event/domain/entities/event_history.dart';
import 'package:lazzo/features/create_event/data/fakes/fake_event_repository.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_history_provider.dart';
import 'package:lazzo/features/create_event/presentation/providers/event_providers.dart';

void main() {
  group('Event History Integration', () {
    test('fetches event history successfully', () async {
      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(FakeEventRepository()),
        ],
      );

      final userId = 'test-user-123';
      final historyAsync = container.read(eventHistoryProvider(userId));

      final history = await historyAsync.future;

      expect(history, isA<List<EventHistory>>());
      expect(history.length, greaterThan(0));
      expect(history.first.name, isNotEmpty);
      expect(history.first.emoji, isNotEmpty);

      container.dispose();
    });

    test('returns events ordered by date descending', () async {
      final container = ProviderContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(FakeEventRepository()),
        ],
      );

      final userId = 'test-user-123';
      final history = await container.read(eventHistoryProvider(userId).future);

      // Verify descending order
      for (int i = 0; i < history.length - 1; i++) {
        expect(
          history[i].startDateTime.isAfter(history[i + 1].startDateTime),
          isTrue,
          reason: 'Events should be ordered newest first',
        );
      }

      container.dispose();
    });
  });
}
```

---

### 3.3 Manual Testing Checklist

**Pre-test setup:**
- [ ] Ensure Supabase has test user with some past events
- [ ] Verify RLS policies allow user to read their own events
- [ ] Check database has events with `status IN ('confirmed', 'living', 'recap', 'ended')`

**Test scenarios:**

1. **Happy path: User with event history**
   - [ ] Navigate to Create Event page
   - [ ] Tap history icon (top-right)
   - [ ] Verify bottom sheet shows list of events
   - [ ] Verify events are ordered newest first
   - [ ] Verify each event shows: emoji, name, time, location
   - [ ] Tap event → verify form pre-fills with data

2. **Edge case: User with no events**
   - [ ] Use new test user with no events
   - [ ] Tap history icon
   - [ ] Verify shows "No events yet" message

3. **Edge case: Events without location**
   - [ ] Verify events without location still display correctly
   - [ ] Location should be empty/hidden in tile

4. **Performance test:**
   - [ ] With 10+ events, verify bottom sheet loads quickly (<1s)
   - [ ] Scroll through list should be smooth

5. **Error handling:**
   - [ ] Disconnect internet
   - [ ] Tap history icon
   - [ ] Verify error message shows
   - [ ] Reconnect → retry should work

**Debug checklist:**
- [ ] Add debug print in `getUserEventHistory` data source
- [ ] Verify query returns data in console
- [ ] Check parsed dates are correct (timezone handling)
- [ ] Verify location JOIN returns data

---

## Part 4: Performance Monitoring

### Metrics to track:

1. **Query performance:**
   - Query execution time: target <100ms
   - Number of rows scanned (should use index)

2. **UI responsiveness:**
   - Bottom sheet open time: target <500ms
   - Scroll performance: 60fps

3. **Network efficiency:**
   - Single query (no N+1)
   - Minimal payload (only required columns)

### Optimization opportunities (future):

1. **Client-side caching:**
   - Cache event history for 5 minutes (Riverpod `.keepAlive()`)
   - Invalidate on event creation

2. **Pagination:**
   - If user has >50 events, implement "Load more"
   - Current limit of 10 is sufficient for MVP

3. **Materialized view:**
   - If query becomes slow, denormalize into `user_event_history` view
   - Refresh on event create/update trigger

---

## Part 5: Rollout Plan

### Phase 1: Backend Implementation (P2)
- [ ] Verify database indexes
- [ ] Create domain entities and repository interface
- [ ] Implement data layer (data source, model, repository)
- [ ] Update fake repository for P1 testing
- [ ] Write unit tests

### Phase 2: Frontend Integration (P1/P2 collaboration)
- [ ] Create providers
- [ ] Update Create Event page to use real data
- [ ] Remove mock data
- [ ] Test UI states (loading, empty, error)

### Phase 3: Testing & QA
- [ ] Run unit tests
- [ ] Run integration tests
- [ ] Manual testing checklist
- [ ] Performance monitoring

### Phase 4: Production Deployment
- [ ] Code review
- [ ] Merge to main
- [ ] Deploy to production
- [ ] Monitor errors (Sentry/analytics)
- [ ] Gather user feedback

---

## Appendix A: File Checklist

**New files to create:**
- [ ] `lib/features/create_event/domain/entities/event_history.dart`
- [ ] `lib/features/create_event/domain/usecases/get_user_event_history.dart`
- [ ] `lib/features/create_event/data/models/event_history_model.dart`
- [ ] `lib/features/create_event/presentation/providers/event_history_provider.dart`
- [ ] `test/unit_tests/features/create_event/data/models/event_history_model_test.dart`
- [ ] `test/integration_tests/event_history_flow_test.dart`

**Files to modify:**
- [ ] `lib/features/create_event/domain/repositories/event_repository.dart` (add method)
- [ ] `lib/features/create_event/data/data_sources/event_remote_data_source.dart` (add method)
- [ ] `lib/features/create_event/data/repositories/event_repository_impl.dart` (add method)
- [ ] `lib/features/create_event/data/fakes/fake_event_repository.dart` (add method)
- [ ] `lib/features/create_event/presentation/pages/create_event_page.dart` (remove mock, use provider)
- [ ] `lib/main.dart` (verify DI override exists)

**Files with no changes:**
- `lib/features/create_event/presentation/widgets/event_history_dialog.dart` (already correct)

---

## Appendix B: Common Issues & Solutions

### Issue 1: "Target of URI doesn't exist" for EventHistory
**Cause:** Import path incorrect  
**Solution:** Verify import: `import '../../domain/entities/event_history.dart';`

### Issue 2: Query returns empty list but events exist
**Cause:** RLS policy blocking read  
**Solution:** Check policy allows `created_by = auth.uid()` reads

### Issue 3: Location data is null even though location exists
**Cause:** JOIN syntax incorrect  
**Solution:** Verify `locations (display_name, ...)` syntax in select

### Issue 4: DateTime parsing fails
**Cause:** Timezone mismatch or invalid ISO format  
**Solution:** Ensure database stores `timestamptz`, use `DateTime.parse()`

### Issue 5: Bottom sheet doesn't show after query
**Cause:** `AsyncValue` states not handled correctly  
**Solution:** Debug `ref.watch()` and verify `.when()` callbacks execute

---

## Success Criteria

**Feature is complete when:**
- ✅ User can view their last 10 events in bottom sheet
- ✅ Events ordered by date (newest first)
- ✅ Selecting event pre-fills create form
- ✅ Empty state shows for users with no events
- ✅ Error state shows if query fails
- ✅ Loading state shows during fetch
- ✅ Query executes in <100ms
- ✅ No N+1 queries (single query with JOIN)
- ✅ RLS enforced (user only sees their events)
- ✅ All unit tests pass
- ✅ All integration tests pass
- ✅ Manual testing checklist complete
- ✅ `flutter analyze` passes with 0 errors
- ✅ Code reviewed and merged

---

**Estimated effort:**
- Database verification: 30 min
- Domain layer: 1 hour
- Data layer: 2 hours
- Presentation layer: 1.5 hours
- Testing: 2 hours
- **Total: ~7 hours**

**Dependencies:**
- Supabase access (for database verification)
- Test user with past events (for manual testing)

**Next steps after completion:**
- [ ] Update `supabase_structure.sql` and re-export `supabase_schema.sql` with index info
- [ ] Document event history feature in `README.md`
- [ ] Add analytics event for "event_history_opened"
- [ ] Consider adding "favorite events" feature (bookmark most-used templates)
