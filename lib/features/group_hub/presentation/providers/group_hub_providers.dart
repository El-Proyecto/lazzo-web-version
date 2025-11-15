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
import '../../data/fakes/fake_group_event_repository.dart';
import '../../data/fakes/fake_group_memory_repository.dart';
import '../../data/fakes/fake_group_details_repository.dart';
import '../../data/fakes/fake_group_photos_repository.dart';

// Repository providers - defaults to fake
final groupEventRepositoryProvider = Provider<GroupEventRepository>((ref) {
  return FakeGroupEventRepository();
});

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

// State providers
final groupEventsProvider = StateNotifierProvider.family<GroupEventsController,
    AsyncValue<List<GroupEventEntity>>, String>((
  ref,
  groupId,
) {
  return GroupEventsController(
    ref.watch(getGroupEventsUseCaseProvider),
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
  memoryId,
) {
  return GroupPhotosController(
    ref.watch(groupPhotosRepositoryProvider),
    memoryId,
  );
});

// Controllers
class GroupEventsController
    extends StateNotifier<AsyncValue<List<GroupEventEntity>>> {
  final GetGroupEvents _getGroupEvents;
  final String _groupId;

  GroupEventsController(this._getGroupEvents, this._groupId)
      : super(const AsyncValue.loading()) {
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
}

class GroupPhotosController
    extends StateNotifier<AsyncValue<List<GroupPhotoEntity>>> {
  final GroupPhotosRepository _repository;
  final String _memoryId;

  GroupPhotosController(this._repository, this._memoryId)
      : super(const AsyncValue.loading()) {
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    state = const AsyncValue.loading();
    try {
      final photos = await _repository.getMemoryPhotos(_memoryId);
      state = AsyncValue.data(photos);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadPhotos();
  }
}
