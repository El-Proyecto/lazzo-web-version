import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/create_event.dart';
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

/// Create Event Controller provider for managing form state
final createEventControllerProvider = StateNotifierProvider<CreateEventController, CreateEventState>((ref) {
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

  CreateEventController({
    required CreateEventUseCase createEventUseCase,
  }) : _createEventUseCase = createEventUseCase,
       super(const CreateEventState());

  /// Create a new event
  Future<void> createEvent(Event event) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final createdEvent = await _createEventUseCase.execute(
        name: event.name,
        emoji: event.emoji,
        groupId: event.groupId,
        startDateTime: event.startDateTime,
        endDateTime: event.endDateTime,
        location: event.location,
      );
      state = state.copyWith(
        isLoading: false,
        createdEvent: createdEvent,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const CreateEventState();
  }
}

/// Provider for getting events by group
final eventsForGroupProvider = FutureProvider.family<List<Event>, String>((ref, groupId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventsForGroup(groupId);
});

/// Provider for searching locations
final locationSearchProvider = FutureProvider.family<List<EventLocation>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final repository = ref.watch(eventRepositoryProvider);
  return repository.searchLocations(query);
});

/// Provider for getting current location
final currentLocationProvider = FutureProvider<EventLocation?>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getCurrentLocation();
});