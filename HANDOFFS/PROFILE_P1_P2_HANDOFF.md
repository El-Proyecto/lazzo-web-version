# Profile Feature - P1 to P2 Handoff Document

**Date**: 18 September 2025  
**Feature**: Profile Page  
**Status**: P1 Complete ✅ - Ready for P2 Data Implementation

---

## 📋 **P1 Deliverables Summary**

### ✅ **Domain Layer (Contracts)**
**Location**: `lib/features/profile/domain/`

- **Entities**:
  - `ProfileEntity` - Core user profile with id, name, profileImageUrl, location, birthday, memories
  - `MemoryEntity` - Memory with id, title, coverImageUrl, date, location

- **Repository Interface**: `ProfileRepository`
  ```dart
  Future<ProfileEntity> getCurrentUserProfile();
  Future<ProfileEntity> getProfileById(String userId);
  Future<ProfileEntity> updateProfile(ProfileEntity profile);
  Future<List<MemoryEntity>> getUserMemories(String userId);
  ```

- **Use Cases**:
  - `GetCurrentUserProfile` - Fetch current user's profile
  - `GetProfileById` - Fetch any user's profile by ID
  - `GetUserMemories` - Fetch user's memories by ID

### ✅ **Presentation Layer**
**Location**: `lib/features/profile/presentation/`

- **Page**: `ProfilePage` - Complete responsive profile page with:
  - AsyncValue state management
  - Loading/error/success states
  - Mobile-first design
  - Proper spacing and tokenization

- **Providers**: `profile_providers.dart`
  - `profileRepositoryProvider` → defaults to FakeProfileRepository
  - `currentUserProfileProvider` → FutureProvider for current user
  - `profileByIdProvider` → FutureProvider.family for any user
  - `userMemoriesProvider` → FutureProvider.family for memories

### ✅ **Shared Components**
**Location**: `lib/shared/components/`

- **ProfileAppBar** (`nav/profile_app_bar.dart`)
  - Tokenized app bar with edit profile icon
  - Reusable across profile features

- **UserInfoCard** (`cards/user_info_card.dart`)
  - Profile picture, name, location, birthday
  - Handles optional fields gracefully
  - Fallback icons for missing data

- **MemoryCard** (`cards/memory_card.dart`)
  - Cover image with gradient overlay
  - Title, location + date format: "Location • Date"
  - Smart location truncation (removes countries, keeps main words)
  - Square aspect ratio, responsive design

- **MemoriesSection** (`sections/memories_section.dart`)
  - Grid layout for memories (2 columns)
  - Empty state handling
  - Responsive spacing

### ✅ **Fake Data Implementation**
**Location**: `lib/features/profile/data/fakes/fake_profile_repository.dart`

Mock data includes:
- Complete user profile (Mara Soares)
- 4+ memory examples with various text lengths
- Realistic network delays (600-1000ms)
- Error handling examples

---

## 🎯 **Domain Contracts (STABLE)**

### ProfileEntity Fields
```dart
final String id;
final String name;
final String? profileImageUrl;  // Optional
final String? location;         // Optional
final DateTime? birthday;       // Optional
final List<MemoryEntity> memories;
```

### MemoryEntity Fields
```dart
final String id;
final String title;
final String? coverImageUrl;    // Optional
final DateTime date;
final String? location;         // Optional
```

### Repository Methods (DO NOT CHANGE)
```dart
abstract class ProfileRepository {
  Future<ProfileEntity> getCurrentUserProfile();
  Future<ProfileEntity> getProfileById(String userId);
  Future<ProfileEntity> updateProfile(ProfileEntity profile);
  Future<List<MemoryEntity>> getUserMemories(String userId);
}
```

---

## 🚀 **P2 Implementation Tasks**

### 1. **Data Source** (`data/data_sources/profile_remote_data_source.dart`)
```dart
class ProfileRemoteDataSource {
  final SupabaseClient _client;
  
  // Implement:
  Future<Map<String, dynamic>> getCurrentUserProfile();
  Future<Map<String, dynamic>> getProfileById(String userId);
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData);
  Future<List<Map<String, dynamic>>> getUserMemories(String userId);
}
```

**Supabase Tables Required**:
- `profiles` table: id, name, profile_image_url, location, birthday
- `memories` table: id, user_id, title, cover_image_url, date, location

### 2. **DTO Models** (`data/models/`)
```dart
// profile_model.dart
class ProfileModel {
  static ProfileEntity fromJson(Map<String, dynamic> json) { ... }
  static Map<String, dynamic> toJson(ProfileEntity entity) { ... }
}

// memory_model.dart  
class MemoryModel {
  static MemoryEntity fromJson(Map<String, dynamic> json) { ... }
  static Map<String, dynamic> toJson(MemoryEntity entity) { ... }
}
```

### 3. **Repository Implementation** (`data/repositories/profile_repository_impl.dart`)
```dart
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _dataSource;
  
  // Bridge data source ↔ domain entities
  // Handle errors and normalize responses
}
```

### 4. **DI Override** (`main.dart`)
```dart
// Replace in ProviderScope overrides:
profileRepositoryProvider.overrideWith(
  (ref) => ProfileRepositoryImpl(
    ProfileRemoteDataSource(Supabase.instance.client),
  ),
),
```

---

## 🎨 **UI Features & Behavior**

### **Implemented Features**
- ✅ Profile picture with fallback
- ✅ User name display
- ✅ Optional location with icon
- ✅ Optional birthday with icon (formatted as "15 July")
- ✅ Memories grid (2 columns, responsive)
- ✅ Memory cards with cover images
- ✅ Smart location truncation: "Bologna • 10 Mar"
- ✅ Empty state for no memories
- ✅ Loading states and error handling
- ✅ Edit profile button (placeholder)
- ✅ Memory tap interactions (placeholder)
- ✅ White background "coming soon" messages

### **Location + Date Format**
- Always shows both parameters
- Format: `"Location • Date"`
- Smart truncation removes countries/cities suffixes
- Examples:
  - `"Bologna • 10 Mar"`
  - `"São Francisco • 11 Feb"`
  - `"Unknown • 8 Oct"` (when location is null)

---

## 🔧 **Testing**

### **Current Testing Setup**
1. Set `initialRoute: AppRouter.profile` in `app.dart`
2. Run `flutter run`
3. Profile loads with fake data in ~800ms

### **P2 Testing Checklist**
- [ ] Real data loads from Supabase
- [ ] RLS policies respected
- [ ] Error handling works
- [ ] Loading states proper
- [ ] Image URLs load correctly
- [ ] Profile updates work
- [ ] Memory CRUD operations
- [ ] Performance (consider pagination for memories)

---

## 📐 **Design System Compliance**

- ✅ All colors use `BrandColors.*` tokens
- ✅ All spacing uses `Gaps.*`, `Insets.*`, `Pads.*`
- ✅ All typography uses `AppText.*`
- ✅ All radii use `Radii.*`
- ✅ Responsive design with constraints
- ✅ Dark theme compatible
- ✅ Accessibility considerations

---

## 🚫 **P2 Constraints**

### **DO NOT CHANGE**:
- Domain entity field names/types
- Repository interface method signatures
- Shared component APIs
- Provider names and return types

### **P2 MUST IMPLEMENT**:
- RLS security policies
- Minimal column selection
- Proper error handling
- Image storage paths following convention
- Performance considerations (indexing, limiting)

---

## 📁 **File Structure Created**

```
lib/features/profile/
├── domain/
│   ├── entities/
│   │   └── profile_entity.dart ✅
│   ├── repositories/
│   │   └── profile_repository.dart ✅
│   └── usecases/
│       ├── get_current_user_profile.dart ✅
│       ├── get_profile_by_id.dart ✅
│       └── get_user_memories.dart ✅
├── data/
│   └── fakes/
│       └── fake_profile_repository.dart ✅
└── presentation/
    ├── pages/
    │   └── profile_page.dart ✅
    └── providers/
        └── profile_providers.dart ✅

lib/shared/components/
├── nav/
│   └── profile_app_bar.dart ✅
├── cards/
│   ├── user_info_card.dart ✅
│   └── memory_card.dart ✅
└── sections/
    └── memories_section.dart ✅
```

---

## 🎯 **Success Criteria**

**P2 is complete when**:
1. Profile loads real data from Supabase
2. All repository methods implemented
3. DTO models handle JSON parsing
4. Error states work properly
5. DI override switches to real implementation
6. **NO changes needed in presentation layer**

**Estimated P2 effort**: 6-8 hours
**Risk areas**: Image storage, RLS policies, memory pagination

---

**Contact**: Handoff complete - P1 ready for P2 implementation.  
**Next**: Implement Supabase data layer following contracts above.