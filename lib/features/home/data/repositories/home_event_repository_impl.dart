import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/home_event.dart';
import '../../domain/repositories/home_event_repository.dart';
import '../data_sources/home_event_remote_data_source.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Repository implementation for home events
/// Bridges data source and domain layer
class HomeEventRepositoryImpl implements HomeEventRepository {
  final HomeEventRemoteDataSource dataSource;
  final Ref ref; // ✅ Inject ref to access current user

  HomeEventRepositoryImpl(this.dataSource, this.ref);

  String? get _currentUserId {
    // Import auth provider to get current user ID
    // Will be properly typed after importing
    try {
      final authState = ref.read(authProvider);
      return authState.valueOrNull?.id;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<HomeEventEntity?> getNextEvent() async {
    final userId = _currentUserId;
    if (userId == null) {
      return null;
    }
    return await dataSource.fetchNextEvent(userId);
  }

  @override
  Future<List<HomeEventEntity>> getConfirmedEvents() async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }
    return await dataSource.fetchConfirmedEvents(userId);
  }

  @override
  Future<List<HomeEventEntity>> getPendingEvents() async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }
    return await dataSource.fetchPendingEvents(userId);
  }

  @override
  Future<List<HomeEventEntity>> getLivingAndRecapEvents() async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }
    return await dataSource.fetchLivingAndRecapEvents(userId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNT & PAGINATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<int> getConfirmedEventsCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;
    return await dataSource.getConfirmedEventsCount(userId);
  }

  @override
  Future<int> getPendingEventsCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;
    return await dataSource.getPendingEventsCount(userId);
  }

  @override
  Future<List<HomeEventEntity>> getConfirmedEventsPaginated({
    required int limit,
    required int offset,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];
    return await dataSource.fetchConfirmedEventsPaginated(
      userId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<HomeEventEntity>> getPendingEventsPaginated({
    required int limit,
    required int offset,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];
    return await dataSource.fetchPendingEventsPaginated(
      userId,
      limit: limit,
      offset: offset,
    );
  }
}
