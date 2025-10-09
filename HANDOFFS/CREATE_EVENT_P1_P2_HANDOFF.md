# Create Event Feature - P1 to P2 Handoff Documentation


 ---------------------------------- DONE ---------------------------------- 


**Date:** 17 de setembro de 2025  
**Feature:** Create Event page with comprehensive validation system  
**P1 Status:** ✅ COMPLETE - Ready for P2  
**P2 Focus:** Data layer implementation and native integrations  

## 📋 Executive Summary

The Create Event feature UI layer (P1) is complete with comprehensive validation, draft saving, and error handling. All components follow Clean Architecture principles and use design tokens. P2 needs to implement the data layer with Supabase integration and native platform features.

---

## ✅ P1 Deliverables Completed

### 🎨 **UI Components (All Tokenized & Stateless)**
- **CreateEventPage** - Main orchestrating page with validation state management
- **EventGroupSelector** - Name/emoji/group selection with inline error display  
- **DateTimeSection** - Start/end date selection with "Decide later" vs "Set now" modes
- **LocationSection** - Location selection with search, map, and current location options
- **ExitConfirmationDialog** - Side-by-side Save Draft/Discard popup dialog

### 🏗️ **Domain Layer Contracts** 
- **Event Entity** (`features/create_event/domain/entities/event.dart`)
  - Complete event model with location, status, and timestamps
  - Immutable with copyWith method
- **EventRepository Interface** (`features/create_event/domain/repositories/event_repository.dart`)
  - CRUD operations for events
  - Location search and current location methods
- **CreateEventUseCase** (`features/create_event/domain/usecases/create_event.dart`)
  - Business rules validation
  - Event creation orchestration

### 🎭 **Fake Data Layer**
- **FakeEventRepository** (`features/create_event/data/fakes/fake_event_repository.dart`)
  - Mock implementations with realistic delays
  - Sample location data for development
  - In-memory event storage

### 📱 **State Management & Services**
- **EventDraft Model** - Complete serialization for draft persistence
- **DraftService** - SharedPreferences-based draft saving/loading
- **Validation System** - Progressive validation with error clearing

### ✨ **Key Features Implemented**

#### **Comprehensive Validation System**
- ✅ Required field validation (Name, Group)
- ✅ Location validation for "Set now" mode
- ✅ DateTime validation with End > Start rule
- ✅ Auto-default 6-hour End time when Start is set
- ✅ Progressive error display (only after Continue pressed)
- ✅ Automatic error clearing when fields become valid

#### **Draft System**
- ✅ Auto-save drafts with change detection
- ✅ Exit confirmation with Save/Discard options
- ✅ Draft restoration on page load
- ✅ JSON serialization with proper error handling

#### **User Experience**
- ✅ Keyboard-safe bottom sheets
- ✅ Conditional button states (gray when invalid, green when valid)
- ✅ Smooth state transitions
- ✅ Proper accessibility considerations

---

## 🚀 P2 Implementation Requirements

### 🗄️ **Data Layer Implementation**

#### **1. Supabase Event Repository** (`features/create_event/data/repositories/event_repository_impl.dart`)
```dart
class EventRepositoryImpl implements EventRepository {
  final SupabaseClient _client;
  
  // Implement all interface methods using Supabase
  // Follow RLS policies
  // Select minimal columns as per agent guide
}
```

#### **2. Event Data Source** (`features/create_event/data/data_sources/event_data_source.dart`)
```dart
class EventDataSource {
  final SupabaseClient _client;
  
  // Raw Supabase operations
  // RPC calls for complex operations
  // Storage operations for media
}
```

#### **3. Event DTO/Models** (`features/create_event/data/models/event_model.dart`)
```dart
class EventModel {
  // JSON serialization
  // Entity conversion methods
  // Supabase row mapping
}
```

### 🌍 **Native Platform Integrations**

#### **1. Geocoding Implementation** 
**File:** `lib/shared/components/sections/location_section.dart`
**Method:** `_performNativeGeocode(String query)`

```dart
Future<List<LocationSuggestion>> _performNativeGeocode(String query) async {
  if (Platform.isIOS) {
    // Use MKLocalSearch or CLGeocoder
    // Handle iOS-specific location search
  } else if (Platform.isAndroid) {
    // Use Android Geocoder
    // Handle Android-specific location search
  }
  
  // Convert platform results to LocationInfo
  return suggestions;
}
```

**Requirements:**
- iOS: Implement MKLocalSearch/CLGeocoder integration
- Android: Implement Geocoder API integration  
- Error handling for permissions and network issues
- Fallback to existing mock data during development

#### **2. URL Launcher Implementation**
**File:** `lib/shared/components/sections/location_section.dart`
**Method:** `_openInMaps(LocationInfo location)`

```dart
void _openInMaps(LocationInfo location) async {
  final url = Platform.isIOS 
    ? 'http://maps.apple.com/?q=${location.latitude},${location.longitude}'
    : 'geo:${location.latitude},${location.longitude}';
    
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    // Show error message
  }
}
```

**Requirements:**
- Add `url_launcher` dependency to pubspec.yaml
- Handle platform-specific map URLs
- Error handling for unavailable map apps

### 🔧 **Dependency Injection Setup**

#### **Update main.dart**
```dart
ProviderScope(
  overrides: [
    eventRepositoryProvider.overrideWithValue(
      EventRepositoryImpl(supabaseClient)
    ),
  ],
  child: App(),
)
```

#### **Create Providers** (`features/create_event/presentation/providers/`)
```dart
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  // Default to fake for development
  return FakeEventRepository();
});

final createEventUseCaseProvider = Provider<CreateEventUseCase>((ref) {
  return CreateEventUseCase(ref.watch(eventRepositoryProvider));
});
```

---

## 📊 Database Schema Requirements

### **Events Table**
```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '🍖',
  group_id UUID NOT NULL REFERENCES groups(id),
  start_datetime TIMESTAMPTZ,
  end_datetime TIMESTAMPTZ,
  location_id UUID REFERENCES locations(id),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'planning', 'confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id)
);
```

### **Locations Table**
```sql
CREATE TABLE locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name TEXT,
  formatted_address TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### **RLS Policies**
- Users can only create events in groups they belong to
- Users can only read/update events they created or are invited to
- Location data should be accessible to all authenticated users

---

## 🧪 Testing Strategy for P2

### **Unit Tests**
- EventRepositoryImpl with mock Supabase client
- Data source operations
- Model serialization/deserialization
- Use case business logic

### **Integration Tests**
- End-to-end event creation flow
- Draft persistence with real SharedPreferences
- Native geocoding with test locations
- URL launcher with mock URLs

### **UI Tests**
- Form validation scenarios
- Draft save/restore workflows
- Error state handling
- Navigation flows

---

## 📁 File Structure Reference

```
lib/features/create_event/
├── domain/
│   ├── entities/
│   │   └── event.dart ✅
│   ├── repositories/
│   │   └── event_repository.dart ✅
│   └── usecases/
│       └── create_event.dart ✅
├── data/
│   ├── data_sources/
│   │   └── event_data_source.dart ❌ (P2)
│   ├── models/
│   │   └── event_model.dart ❌ (P2)
│   ├── repositories/
│   │   └── event_repository_impl.dart ❌ (P2)
│   └── fakes/
│       └── fake_event_repository.dart ✅
└── presentation/
    ├── pages/
    │   └── create_event_page.dart ✅
    ├── providers/
    │   └── event_providers.dart ❌ (P2)
    └── widgets/ (empty - using shared components)

lib/shared/
├── components/
│   ├── forms/
│   │   └── event_group_selector.dart ✅
│   ├── sections/
│   │   ├── date_time_section.dart ✅
│   │   └── location_section.dart ✅ (needs native methods)
│   └── dialogs/
│       └── exit_confirmation_dialog.dart ✅
├── models/
│   └── event_draft.dart ✅
└── services/
    └── draft_service.dart ✅
```

**Legend:**
- ✅ Complete (P1)
- ❌ To implement (P2)
- 🔧 Needs modification (P2)

---

## 🔍 Quality Checklist for P2

### **Code Quality**
- [ ] All repository methods implement proper error handling
- [ ] RLS policies are respected in all queries
- [ ] Minimal column selection following agent guide
- [ ] Proper use of indexes for performance
- [ ] No Flutter/UI imports in domain layer

### **Performance**
- [ ] Database queries use proper indexes
- [ ] Location search has reasonable debounce/throttling
- [ ] Large result sets are paginated
- [ ] Network calls have timeout handling

### **Security**
- [ ] RLS policies prevent unauthorized access
- [ ] Input validation on all user data
- [ ] Proper handling of sensitive location data
- [ ] No admin keys or bypasses in client code

### **User Experience**
- [ ] Geocoding provides relevant local results
- [ ] Map app opens with correct coordinates
- [ ] Offline state is handled gracefully
- [ ] Loading states are shown for network operations

---

## 🚨 Known Issues & Considerations

### **Current State**
- Location search currently uses mock data
- Map opening shows TODO placeholder
- All data operations use in-memory fake repository
- No network error handling yet

### **Platform Considerations**
- iOS requires location permissions for current location
- Android geocoding may need Google Play Services
- Map app availability varies by device
- Different URL schemes for iOS vs Android maps

### **Performance Notes**
- Location search should be debounced (currently implemented)
- Consider caching location results
- Draft auto-save should be throttled
- Large group lists may need virtualization

---

## 📞 Support & Questions

For questions about the P1 implementation or clarification on P2 requirements:

1. **Architecture Questions**: Refer to `agents.md` and `README.md`
2. **Component Usage**: Check component documentation in source files
3. **State Management**: Review existing providers and draft service
4. **Domain Contracts**: All interfaces are defined and documented

---

**P1 Sign-off:** ✅ Complete - Ready for P2 implementation  
**Next Steps:** P2 can proceed with data layer and native platform integrations
