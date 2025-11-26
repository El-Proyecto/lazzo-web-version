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
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }

  @override
  Future<HomeEventEntity?> getNextEvent() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('❌ Cannot fetch next event: user not authenticated');
      return null;
    }
    return await dataSource.fetchNextEvent(userId);
  }

  @override
  Future<List<HomeEventEntity>> getConfirmedEvents() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('❌ Cannot fetch confirmed events: user not authenticated');
      return [];
    }
    return await dataSource.fetchConfirmedEvents(userId);
  }

  @override
  Future<List<HomeEventEntity>> getPendingEvents() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('❌ Cannot fetch pending events: user not authenticated');
      return [];
    }
    return await dataSource.fetchPendingEvents(userId);
  }
}
