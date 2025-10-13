# Edit Event Feature — P1→P2 Handoff

**Date:** 13 de outubro de 2025  
**Status:** ✅ P1 Complete — Ready for P2  
**Feature:** Edit existing events with validation, state management, and proper navigation

---

## 🎯 Feature Scope

**Edit Event Page** allows users to:
- ✅ Edit event name with real-time validation
- ✅ Change event emoji via emoji selector
- ✅ Modify date/time settings (set now vs decide later)
- ✅ Update location (set now vs decide later)
- ✅ Save changes with proper validation
- ✅ Delete events with confirmation
- ✅ Handle unsaved changes dialog
- ✅ Navigate back with proper state management

---

## 📋 P1 Deliverables (Complete)

### ✅ Domain Layer
**Entities** - `features/create_event/domain/entities/event.dart`
```dart
class Event {
  final String id;
  final String name;
  final String emoji;
  final String groupId;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final EventLocation? location;
  final EventStatus status;
  final DateTime createdAt;
}

class EventLocation {
  final String id;
  final String displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;
}

enum EventStatus { pending, confirmed, ended }
```

**Repository Interface** - `features/create_event/domain/repositories/event_repository.dart`
```dart
abstract class EventRepository {
  Future<Event> createEvent(Event event);
  Future<Event?> getEventById(String id);
  Future<Event> updateEvent(Event event);
  Future<void> deleteEvent(String id);
  Future<List<Event>> getEventsForGroup(String groupId);
  Future<List<EventLocation>> searchLocations(String query);
  Future<EventLocation?> getCurrentLocation();
}
```

**Use Cases** - `features/create_event/domain/usecases/`
- ✅ `update_event.dart` - Business rules for event updates
- ✅ `delete_event.dart` - Business rules for event deletion
- ✅ `create_event.dart` - Business rules for event creation

### ✅ Presentation Layer
**Page** - `features/create_event/presentation/pages/edit_event_page.dart`
- ✅ Full Riverpod integration with `ConsumerStatefulWidget`
- ✅ Change detection logic (`_hasChanges()`)
- ✅ Form validation (`_isFormValid()`)
- ✅ State management for all form fields
- ✅ Error handling with SnackBar feedback
- ✅ Loading states with CircularProgressIndicator
- ✅ Proper navigation handling

**Widgets** - Reuses tokenized widgets from create_event:
- ✅ `event_group_selector.dart` - Name/emoji editing with validation
- ✅ `date_time_section.dart` - Date/time picker with states
- ✅ `location_section.dart` - Location picker with states
- ✅ `create_event_app_bar.dart` - App bar with back/delete actions
- ✅ Confirmation dialogs for save/delete/unsaved changes

**Providers** - `features/create_event/presentation/providers/event_providers.dart`
```dart
// Edit Event Controller
final editEventControllerProvider = StateNotifierProvider<EditEventController, EditEventState>((ref) {
  return EditEventController(
    updateEventUseCase: ref.watch(updateEventUseCaseProvider),
    deleteEventUseCase: ref.watch(deleteEventUseCaseProvider),
  );
});

class EditEventState {
  final bool isLoading;
  final String? error;
  final Event? updatedEvent;
  final bool isDeleting;
  final bool isDeleted;
}

class EditEventController extends StateNotifier<EditEventState> {
  Future<void> updateEvent({...});
  Future<void> deleteEvent(String eventId);
  void reset();
}
```

### ✅ Data Layer (Fake Implementation)
**Fake Repository** - `features/create_event/data/fakes/fake_event_repository.dart`
- ✅ Complete implementation of all repository methods
- ✅ In-memory storage with test data
- ✅ Realistic async delays (200-500ms)
- ✅ Proper error handling for edge cases

---

## 🔧 Technical Implementation Details

### State Management Pattern
```dart
// Page listens to controller state
ref.listen<EditEventState>(editEventControllerProvider, (previous, next) {
  if (next.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${next.error}'), backgroundColor: Colors.red),
    );
  }
});

// Button shows loading state
child: editState.isLoading 
    ? CircularProgressIndicator()
    : Text('Save Changes')
```

### Form Validation Logic
```dart
bool _isFormValid() {
  bool nameValid = _eventName.trim().isNotEmpty;
  bool groupValid = _selectedGroup != null || widget.event.groupId.isNotEmpty;
  bool dateTimeValid = (_dateTimeState == DateTimeState.decideLater ||
      (_selectedDate != null && _selectedTime != null));
  bool locationValid = (_locationState == LocationState.decideLater ||
      _selectedLocation != null);
  return nameValid && groupValid && dateTimeValid && locationValid;
}
```

### Change Detection
```dart
bool _hasChanges() {
  return _eventName != _initialEventName ||
      _eventEmoji != _initialEventEmoji ||
      _selectedGroup?.id != _initialSelectedGroup?.id ||
      _selectedDate != _initialSelectedDate ||
      _selectedTime != _initialSelectedTime ||
      _endDate != _initialEndDate ||
      _endTime != _initialEndTime ||
      _selectedLocation?.id != _initialSelectedLocation?.id ||
      _dateTimeState != _initialDateTimeState ||
      _locationState != _initialLocationState;
}
```

### Navigation Logic
- **Green Button**: Saves directly without confirmation popup
- **Unsaved Changes**: Shows confirmation dialog when navigating away
- **Delete**: Shows destructive confirmation dialog
- **Success**: Navigates back to previous page

---

## 🎨 UI/UX Behavior (Implemented)

### Save Button States
- **Grey**: No changes or form invalid
- **Green**: Valid changes ready to save
- **Loading**: Shows spinner during save operation

### Event Name Editor
- **Pre-filled**: Shows current name (not placeholder)
- **Validation**: "Event name is required" error
- **Button States**: Green when valid, grey when empty

### Form Sections
- **Event Name**: Required field with inline editing
- **Group**: Read-only in edit mode (preserves original group)
- **Date/Time**: Toggle between "Set Now" and "Decide Later"
- **Location**: Toggle between "Set Now" and "Decide Later"

---

## 📡 P2 Integration Points

### Repository Implementation Needed
**File:** `features/create_event/data/repositories/event_repository_impl.dart`

```dart
class EventRepositoryImpl implements EventRepository {
  final EventDataSource _dataSource;
  
  EventRepositoryImpl(this._dataSource);

  @override
  Future<Event> updateEvent(Event event) async {
    // 1. Call _dataSource.updateEvent(event.toModel())
    // 2. Convert returned model to Event entity
    // 3. Handle Supabase errors (network, permissions, etc.)
    // 4. Return updated Event entity
  }

  @override
  Future<void> deleteEvent(String id) async {
    // 1. Call _dataSource.deleteEvent(id)
    // 2. Handle Supabase errors
    // 3. Ensure proper RLS permissions
  }

  // ... implement other methods
}
```

### Data Source Implementation Needed
**File:** `features/create_event/data/data_sources/event_data_source.dart`

```dart
class EventDataSource {
  final SupabaseClient _client;
  
  EventDataSource(this._client);

  Future<Map<String, dynamic>> updateEvent(Map<String, dynamic> eventData) async {
    // UPDATE events SET ... WHERE id = ? AND user_can_edit = true
    // Include proper RLS check
    // Return updated row
  }

  Future<void> deleteEvent(String id) async {
    // DELETE FROM events WHERE id = ? AND user_can_delete = true
    // Include proper RLS check
  }
}
```

### Model Mapping Needed
**File:** `features/create_event/data/models/event_model.dart`

```dart
class EventModel {
  // Map Event domain entity <-> Supabase row format
  // Handle nullable fields and type conversions
  // Implement toEntity() and fromEntity() methods
}
```

### DI Override Required
**File:** `main.dart`

```dart
ProviderScope(
  overrides: [
    eventRepositoryProvider.overrideWithValue(
      EventRepositoryImpl(EventDataSource(Supabase.instance.client))
    ),
  ],
  child: MyApp(),
)
```

---

## 🧪 Test Data Available

### Mock Events in Fake Repository
```dart
Event(
  id: '1',
  name: 'Churrascada no Parque',
  emoji: '🍖',
  groupId: '1',
  startDateTime: DateTime.now().add(Duration(days: 2, hours: 14)),
  endDateTime: DateTime.now().add(Duration(days: 2, hours: 20)),
  location: EventLocation(...),
  status: EventStatus.confirmed,
)
```

---

## 🚨 Critical Requirements for P2

### Database Schema Requirements
```sql
-- events table must have:
- id (uuid, primary key)
- name (text, not null)
- emoji (text, not null)
- group_id (uuid, not null, foreign key)
- start_date_time (timestamptz, nullable)
- end_date_time (timestamptz, nullable)
- location_id (uuid, nullable, foreign key to locations)
- status (text, not null, check constraint)
- created_at (timestamptz, not null)
- updated_at (timestamptz, not null)

-- RLS policies required:
- Users can only edit events they created
- Users can only edit events from groups they belong to
- Users can only delete events they created
```

### API Endpoints Required
- `PUT /events/:id` - Update event
- `DELETE /events/:id` - Delete event
- Proper error responses (400, 403, 404, 500)

### Error Handling
- Network connectivity issues
- Permission denied (RLS)
- Event not found
- Validation errors from backend
- Concurrent modification conflicts

---

## ✅ P1 Quality Checklist (Complete)

- [x] **Clean Architecture**: Domain has no Flutter/Supabase imports
- [x] **Design Tokens**: All UI uses tokens from `shared/`
- [x] **State Management**: Proper Riverpod integration with AsyncValue
- [x] **Error Handling**: User-friendly error messages
- [x] **Loading States**: Visual feedback during operations
- [x] **Navigation**: Proper back navigation and dialog handling
- [x] **Validation**: Real-time form validation
- [x] **Change Detection**: Tracks all form field changes
- [x] **Reusable Components**: Uses existing tokenized widgets
- [x] **Fake Data**: Complete mock implementation for development

---

## 🔄 Next Steps for P2

1. **Implement EventRepositoryImpl** with Supabase integration
2. **Create/Update EventDataSource** for database operations
3. **Update DI overrides** in main.dart
4. **Test with real backend** and handle edge cases
5. **Verify RLS policies** work correctly
6. **Performance testing** with real data volumes

---

**Handoff Status:** ✅ **READY FOR P2**  
**P1 Contact:** Available for questions about domain contracts and UI behavior  
**Integration Timeline:** P2 can start immediately - all contracts are stable
