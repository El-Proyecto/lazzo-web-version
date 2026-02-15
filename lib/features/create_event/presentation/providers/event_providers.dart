import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/create_event.dart';
import '../../domain/usecases/update_event.dart';
import '../../domain/usecases/delete_event.dart';
import '../../data/data_sources/event_data_source.dart';
import '../../data/fakes/fake_event_repository.dart';

/// Default EventRepository provider - points to fake for development
/// Will be overridden in main.dart to use real Supabase implementation
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  // Default to fake implementation following agent guide
  return FakeEventRepository();
});

/// EventDataSource provider for Supabase operations
final eventDataSourceProvider = Provider<EventDataSource>((ref) {
  return EventDataSource(Supabase.instance.client);
});

/// CreateEventUseCase provider
final createEventUseCaseProvider = Provider<CreateEventUseCase>((ref) {
  return CreateEventUseCase(ref.watch(eventRepositoryProvider));
});

/// UpdateEventUseCase provider
final updateEventUseCaseProvider = Provider<UpdateEventUseCase>((ref) {
  return UpdateEventUseCase(ref.watch(eventRepositoryProvider));
});

/// DeleteEventUseCase provider
final deleteEventUseCaseProvider = Provider<DeleteEventUseCase>((ref) {
  return DeleteEventUseCase(ref.watch(eventRepositoryProvider));
});

/// Create Event Controller provider for managing form state
final createEventControllerProvider =
    StateNotifierProvider<CreateEventController, CreateEventState>((ref) {
  return CreateEventController(
    createEventUseCase: ref.watch(createEventUseCaseProvider),
  );
});

/// State class for create event form
class CreateEventState {
  final bool isLoading;
  final String? error;
  final Event? createdEvent;

  const CreateEventState({
    this.isLoading = false,
    this.error,
    this.createdEvent,
  });

  CreateEventState copyWith({
    bool? isLoading,
    String? error,
    Event? createdEvent,
  }) {
    return CreateEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdEvent: createdEvent ?? this.createdEvent,
    );
  }
}

/// Controller for managing create event operations
class CreateEventController extends StateNotifier<CreateEventState> {
  final CreateEventUseCase _createEventUseCase;

  CreateEventController({required CreateEventUseCase createEventUseCase})
      : _createEventUseCase = createEventUseCase,
        super(const CreateEventState());

  /// Create a new event
  /// Prevents duplicate calls by checking isLoading state
  Future<void> createEvent(Event event) async {
    // Prevent duplicate calls while already creating
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final createdEvent = await _createEventUseCase.execute(
        name: event.name,
        emoji: event.emoji,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        location: event.location,
        description: event.description,
      );
      state = state.copyWith(isLoading: false, createdEvent: createdEvent);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Rethrow to allow UI to handle error
    }
  }

  /// Reset state
  void reset() {
    state = const CreateEventState();
  }
}

/// Edit Event Controller provider for managing edit operations
final editEventControllerProvider =
    StateNotifierProvider<EditEventController, EditEventState>((ref) {
  return EditEventController(
    updateEventUseCase: ref.watch(updateEventUseCaseProvider),
    deleteEventUseCase: ref.watch(deleteEventUseCaseProvider),
  );
});

/// State class for edit event form
class EditEventState {
  final bool isLoading;
  final String? error;
  final Event? updatedEvent;
  final bool isDeleting;
  final bool isDeleted;

  const EditEventState({
    this.isLoading = false,
    this.error,
    this.updatedEvent,
    this.isDeleting = false,
    this.isDeleted = false,
  });

  EditEventState copyWith({
    bool? isLoading,
    String? error,
    Event? updatedEvent,
    bool? isDeleting,
    bool? isDeleted,
  }) {
    return EditEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      updatedEvent: updatedEvent ?? this.updatedEvent,
      isDeleting: isDeleting ?? this.isDeleting,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Controller for managing edit event operations
class EditEventController extends StateNotifier<EditEventState> {
  final UpdateEventUseCase _updateEventUseCase;
  final DeleteEventUseCase _deleteEventUseCase;

  EditEventController({
    required UpdateEventUseCase updateEventUseCase,
    required DeleteEventUseCase deleteEventUseCase,
  })  : _updateEventUseCase = updateEventUseCase,
        _deleteEventUseCase = deleteEventUseCase,
        super(const EditEventState());

  /// Update an existing event
  Future<void> updateEvent({
    required String eventId,
    required String name,
    required String emoji,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventLocation? location,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedEvent = await _updateEventUseCase.execute(
        eventId: eventId,
        name: name,
        emoji: emoji,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: location,
        description: description,
      );
      state = state.copyWith(isLoading: false, updatedEvent: updatedEvent);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    state = state.copyWith(isDeleting: true, error: null);

    try {
      await _deleteEventUseCase.execute(eventId);
      state = state.copyWith(isDeleting: false, isDeleted: true);
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      rethrow; // Propagate error to UI
    }
  }

  /// Reset state
  void reset() {
    state = const EditEventState();
  }
}

/// Provider for searching locations
final locationSearchProvider =
    FutureProvider.family<List<EventLocation>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final repository = ref.watch(eventRepositoryProvider);
  return repository.searchLocations(query);
});

/// Provider for getting current location
final currentLocationProvider = FutureProvider<EventLocation?>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getCurrentLocation();
});
