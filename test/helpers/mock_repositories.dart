import 'package:mocktail/mocktail.dart';

// Auth Feature Mocks
import 'package:app/features/auth/domain/repositories/auth_repository.dart';

// Home Feature Mocks
import 'package:app/features/home/domain/repositories/memory_repository.dart';

// Create Event Feature Mocks
import 'package:app/features/create_event/domain/repositories/event_repository.dart';

// Groups Feature Mocks
import 'package:app/features/groups/domain/repositories/group_repository.dart';

// Profile Feature Mocks
import 'package:app/features/profile/domain/repositories/profile_repository.dart';

/// Mock repository classes for testing
///
/// Usage:
/// ```dart
/// final mockAuthRepo = MockAuthRepository();
/// when(() => mockAuthRepo.getCurrentUser()).thenReturn(null);
/// ```

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMemoryRepository extends Mock implements MemoryRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

/// Utility function to register fallback values for common types
/// Call this in setUpAll() of your test files
void registerFallbackValues() {
  // Register fallback values for common types used in repository methods
  // Add more as needed when you encounter "A value was requested from a mock
  // but was not configured" errors

  // Example:
  // registerFallbackValue(FakeUser());
  // registerFallbackValue(FakeEvent());
}

/// Example fake classes - implement these as needed for your tests
/// 
/// class FakeUser extends Fake implements User {}
/// class FakeEvent extends Fake implements Event {}