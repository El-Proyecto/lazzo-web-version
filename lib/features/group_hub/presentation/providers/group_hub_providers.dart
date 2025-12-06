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
    AsyncValue<List<GroupEventEntity>>, String>((
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

// Controllers
class GroupEventsController
    extends StateNotifier<AsyncValue<List<GroupEventEntity>>> {
  final GetGroupEvents _getGroupEvents;
  final GroupEventRepository _repository;
  final String _groupId;

  GroupEventsController(
    this._getGroupEvents,
    this._repository,
    this._groupId,
  ) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _getGroupEvents(_groupId);
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadEvents();
  }

  /// Refresh only a specific event without reloading the entire list
  /// This maintains scroll position and improves UX
  Future<void> refreshSingleEvent(String eventId) async {
    print('🔄 [REFRESH] Starting refresh for single event: $eventId');
    
    final currentState = state;
    if (!currentState.hasValue) {
      print('⚠️ [REFRESH] No current state, skipping refresh');
      return;
    }

    try {
      print('📡 [REFRESH] Fetching updated data for event $eventId...');
      
      // Fetch ONLY this specific event (much faster than getting all)
      final updatedEvent = await _repository.getEventById(eventId);
      
      if (updatedEvent == null) {
        print('⚠️ [REFRESH] Event not found: $eventId');
        return;
      }

      print('✅ [REFRESH] Event fetched successfully');
      print('   📊 Going count: ${updatedEvent.goingCount}');
      print('   🎯 User vote: ${updatedEvent.userVote}');
      print('   👥 Total votes: ${updatedEvent.allVotes.length}');

      // Update only the specific event in the list
      final updatedList = currentState.value!.map((event) {
        if (event.id == eventId) {
          print('🔄 [REFRESH] Replacing event in list');
          return updatedEvent;
        }
        return event;
      }).toList();

      state = AsyncValue.data(updatedList);
      print('✅ [REFRESH] State updated successfully without full reload');
    } catch (error, stackTrace) {
      // On error, keep current state instead of showing error
      print('❌ [REFRESH] Failed to refresh single event: $error');
      print('   Stack: $stackTrace');
    }
  }
}

class GroupMemoriesController
    extends StateNotifier<AsyncValue<List<GroupMemoryEntity>>> {
  final GetGroupMemories _getGroupMemories;
  final String _groupId;

  GroupMemoriesController(this._getGroupMemories, this._groupId)
      : super(const AsyncValue.loading()) {
    print('\n🎬 [MEMORIES CONTROLLER] Initializing for groupId: $_groupId');
    loadMemories();
  }

  Future<void> loadMemories() async {
    print('\n📡 [MEMORIES CONTROLLER] Starting loadMemories for groupId: $_groupId');
    state = const AsyncValue.loading();
    print('⏳ [MEMORIES CONTROLLER] State set to loading');
    try {
      print('🔍 [MEMORIES CONTROLLER] Calling use case...');
      final memories = await _getGroupMemories(_groupId);
      print('✅ [MEMORIES CONTROLLER] Use case returned ${memories.length} memories');
      if (memories.isNotEmpty) {
        print('📝 [MEMORIES CONTROLLER] First memory:');
        print('   - ID: ${memories.first.id}');
        print('   - Title: ${memories.first.title}');
        print('   - Cover URL: ${memories.first.coverImageUrl}');
        print('   - Photo count: ${memories.first.photoCount}');
      }
      state = AsyncValue.data(memories);
      print('✅ [MEMORIES CONTROLLER] State updated with data');
    } catch (error, stackTrace) {
      print('❌ [MEMORIES CONTROLLER] ERROR: $error');
      print('   Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    print('🔄 [MEMORIES CONTROLLER] Refresh requested');
    await loadMemories();
  }
}

class GroupDetailsController
    extends StateNotifier<AsyncValue<GroupDetailsEntity>> {
  final GetGroupDetails _getGroupDetails;
  final String _groupId;

  GroupDetailsController(this._getGroupDetails, this._groupId)
      : super(const AsyncValue.loading()) {
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

  /// Toggle mute status and update state optimistically
  void toggleMute() {
    state.whenData((details) {
      final newDetails = details.copyWith(isMuted: !details.isMuted);
      state = AsyncValue.data(newDetails);
    });
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
      final updatedMembers = members.where((member) => member.id != userId).toList();
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
      print('\n🎬 [CONTROLLER] Starting to load photos for group: $_groupId');
      final photos = await _repository.getGroupPhotos(_groupId);
      print('✅ [CONTROLLER] Successfully loaded ${photos.length} photos');
      state = AsyncValue.data(photos);
    } catch (error, stackTrace) {
      print('❌ [CONTROLLER] Error loading photos: $error');
      print('   Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadPhotos();
  }
}
