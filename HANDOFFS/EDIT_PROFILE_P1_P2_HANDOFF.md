# EDIT PROFILE P1-P2 HANDOFF

## Overview
This document outlines the handoff from P1 (UI/Domain) to P2 (Data Layer) for the Edit Profile feature. All domain contracts, shared components, and fake implementations are complete and tested.

## P1 Deliverables (✅ Complete)

### Domain Layer
- **Location**: `lib/features/profile/domain/`
- **Entity**: `ProfileEntity` with all required fields
- **Use Case**: `UpdateProfile` use case implementation
- **Repository**: `ProfileRepository` abstract interface

### Fake Implementation 
- **Location**: `lib/features/profile/data/repositories/fake_profile_repository.dart`
- **Status**: ✅ Complete fake implementation for testing
- **Features**: 
  - Simulated network delays
  - Fake user data generation
  - Error simulation capabilities

### Shared Components (All Tokenized)
All components follow design system tokens and are fully tested:

#### 1. EditableInfoCard
- **Location**: `lib/shared/components/cards/editable_info_card.dart`
- **Purpose**: Reusable editable field component with remove functionality
- **Features**:
  - Consistent remove button styling (28x28 square, bg3 background, red icon)
  - Edit/view mode toggle
  - Validation error display
  - Auto-save on field removal
- **Tokens**: Uses BrandColors.bg3, BrandColors.cantVote

#### 2. IosBirthdayPickerCard  
- **Location**: `lib/shared/components/cards/ios_birthday_picker_card.dart`
- **Purpose**: iOS-style date picker for birthday selection
- **Features**:
  - Future date prevention logic
  - Defaults to current day
  - Consistent styling with other cards
  - Month/day validation based on current year
- **Constraints**: Cannot select dates after current day

#### 3. EditableProfilePhoto
- **Location**: `lib/shared/components/cards/editable_profile_photo.dart`
- **Purpose**: Profile photo display and editing component
- **Features**: 
  - Photo display/placeholder handling
  - Edit mode toggle
  - Integration with photo change sheet

#### 4. EmailInfoCard
- **Location**: `lib/shared/components/cards/email_info_card.dart`
- **Purpose**: Email display component (read-only)
- **Features**: Non-editable email field display

#### 5. PhotoChangeBottomSheet
- **Location**: `lib/shared/components/sheets/photo_change_bottom_sheet.dart`
- **Purpose**: Bottom sheet for photo selection/removal
- **Features**:
  - Gallery, camera, and remove options
  - Conditional remove option based on current photo
  - Tokenized styling

### Presentation Layer
- **Location**: `lib/features/profile/presentation/`
- **Page**: `edit_profile_page.dart` - Complete edit profile screen
- **Provider**: `edit_profile_provider.dart` - Riverpod state management
- **Notifier**: `edit_profile_notifier.dart` - Business logic handling

### State Management
- **Pattern**: Riverpod with AsyncValue
- **Provider**: `editProfileProvider` 
- **Features**:
  - Loading states
  - Error handling  
  - Optimistic updates
  - Auto-save functionality

## P2 Implementation Tasks

### 1. Data Sources
**Create**: `lib/features/profile/data/datasources/profile_remote_data_source.dart`

```dart
abstract class ProfileRemoteDataSource {
  Future<ProfileDto> updateProfile(String userId, ProfileDto profileDto);
  Future<ProfileDto> getProfile(String userId);
}
```

**Implementation**: 
- HTTP client integration
- API endpoint configuration
- Request/response handling
- Error mapping

### 2. DTOs (Data Transfer Objects)
**Create**: `lib/features/profile/data/models/profile_dto.dart`

Required fields mapping:
```dart
class ProfileDto {
  final String id;
  final String firstName;
  final String lastName;
  final String? bio;
  final DateTime? birthday;
  final String? photoUrl;
  final String email;
  final DateTime updatedAt;
  
  // fromJson, toJson, fromEntity, toEntity methods
}
```

### 3. Repository Implementation
**Create**: `lib/features/profile/data/repositories/profile_repository_impl.dart`

```dart
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  
  @override
  Future<Either<Failure, ProfileEntity>> updateProfile(
    String userId, 
    ProfileEntity profileEntity,
  );
  
  @override 
  Future<Either<Failure, ProfileEntity>> getProfile(String userId);
}
```

### 4. Dependency Injection Override
Update providers to use real implementation:

```dart
// In lib/features/profile/presentation/providers/edit_profile_provider.dart
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  // Replace FakeProfileRepository with ProfileRepositoryImpl
  return ProfileRepositoryImpl(
    remoteDataSource: ref.read(profileRemoteDataSourceProvider),
  );
});
```

### 5. Error Handling
Implement proper error handling for:
- Network failures
- Server errors  
- Validation errors
- Authentication errors

### 6. Image Upload (if required)
If profile photo upload is needed:
- Image compression
- Multipart upload handling
- Progress tracking
- Error handling for large files

## API Endpoints (Backend Requirements)

### Update Profile
```
PUT /api/v1/users/{userId}/profile
Content-Type: application/json

Body: ProfileDto JSON
Returns: Updated ProfileDto
```

### Get Profile  
```
GET /api/v1/users/{userId}/profile
Returns: ProfileDto
```

### Upload Profile Photo (if separate endpoint)
```
POST /api/v1/users/{userId}/profile/photo
Content-Type: multipart/form-data
Returns: { "photoUrl": "..." }
```

## Testing Requirements

### Unit Tests
- Repository implementation tests
- Data source tests  
- DTO serialization tests
- Error handling tests

### Integration Tests
- API endpoint integration
- Full update profile flow
- Error scenario handling

## Notes for P2

### Shared Components Usage
All shared components are production-ready and tokenized:
- Use `EditableInfoCard` for all editable text fields
- Use `IosBirthdayPickerCard` for birthday selection
- Use `EditableProfilePhoto` for photo handling
- Use `PhotoChangeBottomSheet` for photo actions

### Domain Contracts
Domain layer is complete and tested. Do not modify:
- `ProfileEntity` structure
- `ProfileRepository` interface  
- `UpdateProfile` use case

### State Management
The presentation layer uses Riverpod. Only update provider implementations, not the presentation logic.

### Design System
All components use design tokens. Maintain consistency with:
- BrandColors for colors
- AppTextStyles for typography
- Component sizing standards

## Validation

### P1 Completion Checklist
- [x] Domain entities defined
- [x] Repository interfaces created
- [x] Use cases implemented
- [x] Fake repository for testing
- [x] All shared components created and tokenized
- [x] Presentation layer complete
- [x] State management implemented
- [x] Compilation successful
- [x] UI/UX requirements met

### P2 Success Criteria
- [ ] Real data layer implementation
- [ ] API integration complete
- [ ] Error handling robust
- [ ] Tests passing
- [ ] Performance optimized
- [ ] Documentation updated

---

**Ready for P2 Implementation** ✅

All domain contracts are stable and shared components are production-ready. P2 can focus purely on data layer implementation without UI concerns.