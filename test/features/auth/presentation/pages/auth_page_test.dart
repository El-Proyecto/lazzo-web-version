import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazzo/features/auth/domain/entities/user.dart' as domain;
import 'package:lazzo/features/auth/domain/repositories/auth_repository.dart';
import 'package:lazzo/features/auth/presentation/pages/auth_page.dart';
import 'package:lazzo/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const domain.User(id: 'u-1', email: 'u@test.com'));
    when(() => mockAuthRepository.register(email: any(named: 'email')))
        .thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifier(mockAuthRepository)),
      ],
      child: const MaterialApp(
        home: AuthPage(),
      ),
    );
  }

  group('AuthPage', () {
    testWidgets('shows email input field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('shows disabled submit button when email is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final submitButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Account'),
      );

      expect(submitButton.onPressed, isNull);
    });

    testWidgets('shows enabled submit button when email is non-empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Monteiro');
      await tester.enterText(find.byType(TextField).at(1), 'monteiro@test.com');
      await tester.pump();

      final submitButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Account'),
      );

      expect(submitButton.onPressed, isNotNull);
    });

    testWidgets('tapping submit calls the auth provider method', (tester) async {
      final completer = Completer<void>();
      when(() => mockAuthRepository.register(email: any(named: 'email')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Monteiro');
      await tester.enterText(find.byType(TextField).at(1), 'monteiro@test.com');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      verify(() => mockAuthRepository.register(email: 'monteiro@test.com')).called(1);

      await tester.pumpWidget(const SizedBox.shrink());
      completer.complete();
    });
  });
}
