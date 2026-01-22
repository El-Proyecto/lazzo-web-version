import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group_event_entity.dart';
import '../../domain/entities/group_memory_entity.dart';
import '../../domain/entities/group_details_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/group_photo_entity.dart';
import '../../domain/repositories/group_event_repository.dart';
import '../../domain/repositories/group_memory_repository.dart';
import '../../domain/repositories/group_details_repository.dart';
import '../../domain/repositories/group_photos_repository.dart';
import '../../domain/usecases/get_group_events.dart';
import '../../domain/usecases/get_group_memories.dart';
import '../../domain/usecases/get_group_details.dart';
import '../../domain/usecases/get_group_members.dart';
import '../../domain/usecases/toggle_group_mute.dart';
import '../../domain/usecases/update_member_role.dart';
import '../../domain/usecases/remove_member.dart';
import '../../data/fakes/fake_group_event_repository.dart';
import '../../data/fakes/fake_group_memory_repository.dart';
import '../../data/fakes/fake_group_details_repository.dart';
import '../../data/fakes/fake_group_photos_repository.dart';

// Repository providers - defaults to fake
//
// P2 TODO: Override these providers in main.dart with real implementations:
// ```dart
// groupEventRepositoryProvider.overrideWith((ref) {
//   final client = Supabase.instance.client;
//   final dataSource = SupabaseGroupEventDataSource(client);
//   return GroupEventRepositoryImpl(dataSource);
// }),
// ```
final groupEventRepositoryProvider = Provider<GroupEventRepository>((ref) {
  return FakeGroupEventRepository();
});

// P2 TODO: Override in main.dart with SupabaseGroupMemoryDataSource + GroupMemoryRepositoryImpl
final groupMemoryRepositoryProvider = Provider<GroupMemoryRepository>((ref) {
  return FakeGroupMemoryRepository();
});

final groupDetailsRepositoryProvider = Provider<GroupDetailsRepository>((ref) {
  return FakeGroupDetailsRepository();
});

final groupPhotosRepositoryProvider = Provider<GroupPhotosRepository>((ref) {
  return FakeGroupPhotosRepository();
});

// Use case providers
final getGroupEventsUseCaseProvider = Provider<GetGroupEvents>((ref) {
  return GetGroupEvents(ref.watch(groupEventRepositoryProvider));
});

final getGroupMemoriesUseCaseProvider = Provider<GetGroupMemories>((ref) {
  return GetGroupMemories(ref.watch(groupMemoryRepositoryProvider));
});

final getGroupDetailsUseCaseProvider = Provider<GetGroupDetails>((ref) {
  return GetGroupDetails(ref.watch(groupDetailsRepositoryProvider));
});

final getGroupMembersUseCaseProvider = Provider<GetGroupMembers>((ref) {
  return GetGroupMembers(ref.watch(groupDetailsRepositoryProvider));
});

final toggleGroupMuteUseCaseProvider = Provider<ToggleGroupMute>((ref) {
  return ToggleGroupMute(ref.watch(groupDetailsRepositoryProvider));
});

final updateMemberRoleUseCaseProvider = Provider<UpdateMemberRole>((ref) {
  return UpdateMemberRole(ref.watch(groupDetailsRepositoryProvider));
});

final removeMemberUseCaseProvider = Provider<RemoveMember>((ref) {
  return RemoveMember(ref.watch(groupDetailsRepositoryProvider));
});

// State providers
final groupEventsProvider = StateNotifierProvider.family<GroupEventsController,
    PaginatedEventsState, String>((
  ref,
  groupId,
) {
  return GroupEventsController(
    ref.watch(getGroupEventsUseCaseProvider),
    ref.watch(groupEventRepositoryProvider),
    groupId,
  );
});

final groupMemoriesProvider = StateNotifierProvider.family<
    GroupMemoriesController, AsyncValue<List<GroupMemoryEntity>>, String>((
  ref,
  groupId,
) {
  return GroupMemoriesController(
    ref.watch(getGroupMemoriesUseCaseProvider),
    groupId,
  );
});

final groupDetailsProvider = StateNotifierProvider.family<
    GroupDetailsController, AsyncValue<GroupDetailsEntity>, String>((
  ref,
  groupId,
) {
  return GroupDetailsController(
    ref.watch(getGroupDetailsUseCaseProvider),
    ref.watch(toggleGroupMuteUseCaseProvider),
    groupId,
  );
});

final groupMembersProvider = StateNotifierProvider.family<
    GroupMembersController, AsyncValue<List<GroupMemberEntity>>, String>((
  ref,
  groupId,
) {
  return GroupMembersController(
    ref.watch(getGroupMembersUseCaseProvider),
    groupId,
  );
});

final groupPhotosProvider = StateNotifierProvider.family<GroupPhotosController,
    AsyncValue<List<GroupPhotoEntity>>, String>((
  ref,
  groupId,
) {
  return GroupPhotosController(
    ref.watch(groupPhotosRepositoryProvider),
    groupId,
  );
});

/// Paginated events state
class PaginatedEventsState {
  final List<GroupEventEntity> events;
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
    List<GroupEventEntity>? events,
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

// Controllers

/// Paginated events controller with infinite scroll support
class GroupEventsController extends StateNotifier<PaginatedEventsState> {
  final GetGroupEvents _getGroupEvents;
  final GroupEventRepository _repository;
  final String _groupId;
  static const int _pageSize = 20;

  GroupEventsController(
    this._getGroupEvents,
    this._repository,
    this._groupId,
  ) : super(const PaginatedEventsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _getGroupEvents(
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
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final newEvents = await _getGroupEvents(
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

  /// Refresh only a specific event without reloading the entire list
  /// This maintains scroll position and improves UX
  Future<void> refreshSingleEvent(String eventId) async {
    if (state.events.isEmpty) {
      return;
    }

    try {
      // Fetch ONLY this specific event (much faster than getting all)
      final updatedEvent = await _repository.getEventById(eventId);

      if (updatedEvent == null) {
        return;
      }

      // Update only the specific event in the list
      final updatedList = state.events.map((event) {
        if (event.id == eventId) {
          return updatedEvent;
        }
        return event;
      }).toList();

      state = state.copyWith(events: updatedList);
    } catch (error) {
      // On error, keep current state instead of showing error
    }
  }
}

class GroupMemoriesController
    extends StateNotifier<AsyncValue<List<GroupMemoryEntity>>> {
  final GetGroupMemories _getGroupMemories;
  final String _groupId;

  GroupMemoriesController(this._getGroupMemories, this._groupId)
      : super(const AsyncValue.loading()) {
    loadMemories();
  }

  Future<void> loadMemories() async {
    state = const AsyncValue.loading();
    try {
      final memories = await _getGroupMemories(_groupId);
      state = AsyncValue.data(memories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadMemories();
  }
}

class GroupDetailsController
    extends StateNotifier<AsyncValue<GroupDetailsEntity>> {
  final GetGroupDetails _getGroupDetails;
  final ToggleGroupMute _toggleGroupMute;
  final String _groupId;

  GroupDetailsController(
    this._getGroupDetails,
    this._toggleGroupMute,
    this._groupId,
  ) : super(const AsyncValue.loading()) {
    loadDetails();
  }

  Future<void> loadDetails() async {
    state = const AsyncValue.loading();
    try {
      final details = await _getGroupDetails(_groupId);
      state = AsyncValue.data(details);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadDetails();
  }

  /// Toggle mute status: update UI optimistically and persist to backend
  Future<void> toggleMute() async {
    // 1. Optimistic update - immediately update UI
    final currentIsMuted = state.value?.isMuted ?? false;
    final newIsMuted = !currentIsMuted;

    state.whenData((details) {
      final newDetails = details.copyWith(isMuted: newIsMuted);
      state = AsyncValue.data(newDetails);
    });

    // 2. Persist to backend
    try {
      await _toggleGroupMute(_groupId, newIsMuted);
    } catch (error) {
      // Rollback on error
      state.whenData((details) {
        final rolledBackDetails = details.copyWith(isMuted: currentIsMuted);
        state = AsyncValue.data(rolledBackDetails);
      });
      rethrow;
    }
  }
}

class GroupMembersController
    extends StateNotifier<AsyncValue<List<GroupMemberEntity>>> {
  final GetGroupMembers _getGroupMembers;
  final String _groupId;

  GroupMembersController(this._getGroupMembers, this._groupId)
      : super(const AsyncValue.loading()) {
    loadMembers();
  }

  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await _getGroupMembers(_groupId);
      state = AsyncValue.data(members);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadMembers();
  }

  /// Optimistic update: immediately updates UI before server confirms
  void updateMemberRoleOptimistically(String userId, bool isAdmin) {
    state.whenData((members) {
      final updatedMembers = members.map((member) {
        if (member.id == userId) {
          return GroupMemberEntity(
            id: member.id,
            name: member.name,
            profileImageUrl: member.profileImageUrl,
            isAdmin: isAdmin,
            isCurrentUser: member.isCurrentUser,
          );
        }
        return member;
      }).toList();

      state = AsyncValue.data(updatedMembers);
    });
  }

  /// Optimistic remove: immediately removes member from UI before server confirms
  void removeMemberOptimistically(String userId) {
    state.whenData((members) {
      final updatedMembers =
          members.where((member) => member.id != userId).toList();
      state = AsyncValue.data(updatedMembers);
    });
  }
}

class GroupPhotosController
    extends StateNotifier<AsyncValue<List<GroupPhotoEntity>>> {
  final GroupPhotosRepository _repository;
  final String _groupId;

  GroupPhotosController(this._repository, this._groupId)
      : super(const AsyncValue.loading()) {
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    state = const AsyncValue.loading();
    try {
      final photos = await _repository.getGroupPhotos(_groupId);
      state = AsyncValue.data(photos);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadPhotos();
  }
}
