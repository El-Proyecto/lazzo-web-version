import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/memory_entity.dart';
import '../../data/fakes/fake_memory_repository.dart';
import '../../data/data_sources/memory_photo_data_source.dart';
import 'memory_providers.dart';
import '../../../home/presentation/providers/home_event_providers.dart';

/// Provider for selected photo paths from gallery
final selectedPhotoPathsProvider = StateProvider<List<String>?>((ref) => null);

/// State for managing memory photos
class ManageMemoryState {
  final String memoryId;
  final List<ManagePhotoItem> allPhotos;
  final ManagePhotoItem? selectedCover;
  final int maxPhotos;
  final bool isHost;
  final String currentUserId;

  const ManageMemoryState({
    required this.memoryId,
    required this.allPhotos,
    this.selectedCover,
    required this.maxPhotos,
    required this.isHost,
    required this.currentUserId,
  });

  ManageMemoryState copyWith({
    List<ManagePhotoItem>? allPhotos,
    ManagePhotoItem? selectedCover,
    bool clearCover = false,
  }) {
    return ManageMemoryState(
      memoryId: memoryId,
      allPhotos: allPhotos ?? this.allPhotos,
      selectedCover: clearCover ? null : (selectedCover ?? this.selectedCover),
      maxPhotos: maxPhotos,
      isHost: isHost,
      currentUserId: currentUserId,
    );
  }
}

/// Photo item for manage memory UI
class ManagePhotoItem {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final bool isPortrait;
  final String uploaderId;
  final String uploaderName;
  final bool isUploadedByCurrentUser;

  const ManagePhotoItem({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.isPortrait,
    required this.uploaderId,
    required this.uploaderName,
    required this.isUploadedByCurrentUser,
  });
}

/// Provider for manage memory state
final manageMemoryProvider = StateNotifierProvider.family<ManageMemoryNotifier,
    AsyncValue<ManageMemoryState>, String>((ref, memoryId) {
  return ManageMemoryNotifier(
    memoryId: memoryId,
    ref: ref,
  );
});

/// State notifier for managing memory
class ManageMemoryNotifier
    extends StateNotifier<AsyncValue<ManageMemoryState>> {
  final String memoryId;
  final Ref ref;

  ManageMemoryNotifier({
    required this.memoryId,
    required this.ref,
  }) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final memoryAsync = await ref.read(memoryDetailProvider(memoryId).future);

      if (memoryAsync == null) {
        state = AsyncValue.error('Memory not found', StackTrace.current);
        return;
      }

      // Get current authenticated user ID from Supabase
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      if (currentUserId == null) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return;
      }

      // Get isHost from fake config (toggle for testing)
      final isHost = FakeMemoryConfig.isHost;

      // Sort photos: user photos first, then others
      final sortedPhotos = List<MemoryPhoto>.from(memoryAsync.photos)
        ..sort((a, b) {
          final aIsUser = a.uploaderId == currentUserId;
          final bIsUser = b.uploaderId == currentUserId;
          if (aIsUser && !bIsUser) return -1;
          if (!aIsUser && bIsUser) return 1;
          return a.capturedAt.compareTo(b.capturedAt);
        });

      final photoItems = sortedPhotos
          .map((p) => ManagePhotoItem(
                id: p.id,
                url: p.url,
                thumbnailUrl: p.thumbnailUrl,
                isPortrait: p.isPortrait,
                uploaderId: p.uploaderId,
                uploaderName: p.uploaderName,
                isUploadedByCurrentUser: p.uploaderId == currentUserId,
              ))
          .toList();

      // Upload selected photos from gallery (if provided)
      final selectedPhotoPaths = ref.read(selectedPhotoPathsProvider);
      if (selectedPhotoPaths != null && selectedPhotoPaths.isNotEmpty) {
        print('📸 Found ${selectedPhotoPaths.length} photos to upload');
        
        // Get real eventId from next event
        final nextEvent = await ref.read(nextEventControllerProvider.future);
        if (nextEvent == null) {
          print('❌ No next event found, cannot upload photos');
          state = AsyncValue.error('No active event to upload photos', StackTrace.current);
          return;
        }
        
        final eventId = nextEvent.id;
        
        // Get groupId from events table (since HomeEventEntity doesn't expose it)
        final eventData = await Supabase.instance.client
            .from('events')
            .select('group_id')
            .eq('id', eventId)
            .single();
        
        final groupId = eventData['group_id'] as String;
        print('🎯 Using real IDs - eventId: $eventId, groupId: $groupId');
        
        final dataSource = MemoryPhotoDataSource(Supabase.instance.client);
        
        for (int i = 0; i < selectedPhotoPaths.length; i++) {
          try {
            final filePath = selectedPhotoPaths[i];
            final file = File(filePath);
            
            print('📤 Uploading photo ${i + 1}/${selectedPhotoPaths.length}...');
            
            // Upload photo to Supabase
            final uploadResult = await dataSource.uploadPhoto(
              groupId: groupId,
              eventId: eventId,
              userId: currentUserId,
              file: file,
              isPortrait: false, // TODO: Detect orientation from image
            );
            
            // Add uploaded photo to the beginning of the list
            photoItems.insert(
              0,
              ManagePhotoItem(
                id: uploadResult['id'] as String,
                url: uploadResult['url'] as String,
                thumbnailUrl: null,
                isPortrait: false,
                uploaderId: currentUserId,
                uploaderName: 'You',
                isUploadedByCurrentUser: true,
              ),
            );
            
            print('✅ Photo ${i + 1} uploaded successfully');
          } catch (e) {
            print('❌ Failed to upload photo ${i + 1}: $e');
            // Continue with other photos even if one fails
          }
        }
        
        // Clear the selected photos provider after upload
        ref.read(selectedPhotoPathsProvider.notifier).state = null;
      }

      // No cover selected by default
      final ManagePhotoItem? currentCover = null;

      // Calculate max photos: max(20, 5 * N people)
      // TODO: Get actual participant count from event
      const participantCount = 4; // Placeholder
      final maxPhotos = (20 > 5 * participantCount) ? 20 : 5 * participantCount;

      state = AsyncValue.data(ManageMemoryState(
        memoryId: memoryId,
        allPhotos: photoItems,
        selectedCover: currentCover,
        maxPhotos: maxPhotos,
        isHost: isHost,
        currentUserId: currentUserId,
      ));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Select a photo as cover
  void selectCover(ManagePhotoItem photo) {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(selectedCover: photo));
    });
  }

  /// Remove cover selection
  void removeCover() {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(clearCover: true));
    });
  }

  /// Remove a photo (only if uploaded by current user)
  Future<void> removePhoto(String photoId) async {
    state.whenData((currentState) async {
      try {
        // Call use case to remove photo
        final removeUseCase = ref.read(removeMemoryPhotoUseCaseProvider);
        final success = await removeUseCase(memoryId, photoId);

        if (!success) {
          state =
              AsyncValue.error('Failed to remove photo', StackTrace.current);
          return;
        }

        // Remove from local state
        final updatedPhotos =
            currentState.allPhotos.where((p) => p.id != photoId).toList();

        // Clear cover if removed photo was the cover
        final clearCover = currentState.selectedCover?.id == photoId;

        state = AsyncValue.data(currentState.copyWith(
          allPhotos: updatedPhotos,
          clearCover: clearCover,
        ));
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    });
  }

  /// Save changes (update cover selection)
  Future<void> saveChanges() async {
    state.whenData((currentState) async {
      try {
        // Call use case to update cover
        final updateUseCase = ref.read(updateMemoryCoverUseCaseProvider);
        await updateUseCase(memoryId, currentState.selectedCover?.id);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    });
  }
}
