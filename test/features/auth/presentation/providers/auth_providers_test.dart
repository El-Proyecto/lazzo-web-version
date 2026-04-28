import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/auth/domain/entities/user.dart' as domain;
import 'package:lazzo/features/auth/domain/repositories/auth_repository.dart';
import 'package:lazzo/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('authProvider / AuthNotifier', () {
    test('initializes with current user', () async {
      const user = domain.User(id: 'user-1', email: 'user@example.com');
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => user);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWith((ref) => AuthNotifier(mockAuthRepository)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider), const AsyncLoading<domain.User?>());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authProvider);
      expect(state.value, user);
    });

    test('sets null user when initialization fails', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenThrow(Exception('init-fail'));

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWith((ref) => AuthNotifier(mockAuthRepository)),
        ],
      );
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authProvider);
      expect(state.value, isNull);
      expect(state.hasError, isFalse);
    });

    test('login trims and lowercases email', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockAuthRepository.login(email: any(named: 'email')))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWith((ref) => AuthNotifier(mockAuthRepository)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      final ok = await notifier.login('  USER@Example.COM ');

      expect(ok, isTrue);
      verify(
        () => mockAuthRepository.login(email: 'user@example.com'),
      ).called(1);
    });

    test('logout sets state to null user', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWith((ref) => AuthNotifier(mockAuthRepository)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      final state = container.read(authProvider);
      expect(state.value, isNull);
      verify(() => mockAuthRepository.logout()).called(1);
    });
  });
}
