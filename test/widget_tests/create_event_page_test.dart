import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lazzo/features/create_event/presentation/pages/create_event_page.dart';
import 'package:lazzo/features/create_event/presentation/widgets/confirm_event_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Widget wrapper com ProviderScope
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('CreateEventPage – LAZZO 2.0 (no groups)', () {
    testWidgets('Sem nome: mostra erro e NÃO abre confirmação', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const CreateEventPage()));

      // Tenta prosseguir imediatamente
      final continueBtn = find.byKey(const Key('continue_button'));
      expect(continueBtn, findsOneWidget);

      await tester.scrollUntilVisible(
        continueBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Erro de nome deve aparecer
      expect(find.text('Event name is required'), findsOneWidget);

      // Confirm dialog NÃO deve abrir
      expect(find.byType(ConfirmEventBottomSheet), findsNothing);
    });

    testWidgets('Com nome apenas: não abre ConfirmEventBottomSheet', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const CreateEventPage()));

      // 1) Abrir editor do nome (tap no texto "Add Event Name" abre o bottom sheet)
      final nameTapTarget = find.text('Add Event Name');
      expect(nameTapTarget, findsOneWidget);
      await tester.tap(nameTapTarget);
      await tester.pumpAndSettle(); // abre o bottom sheet do nome

      // 2) Preencher nome no TextField
      final nameField = find.byKey(const Key('createEvent:name'));
      expect(
        nameField,
        findsOneWidget,
        reason:
            'Garante que passas nameFieldKey ao _EventNameEditBottomSheet e usas widget.nameFieldKey',
      );
      await tester.enterText(nameField, 'Churrasco no Parque');
      await tester.pump();

      // Guardar
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(); // volta à página

      // 3) Prosseguir
      final continueBtn = find.byKey(const Key('continue_button'));
      await tester.scrollUntilVisible(
        continueBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Com a implementação atual, nome sozinho não basta:
      // Date/time e location também são obrigatórios.
      expect(find.byType(ConfirmEventBottomSheet), findsNothing);

      // O erro de nome não deve existir, pois o nome foi preenchido.
      expect(find.text('Event name is required'), findsNothing);

      // Devem aparecer erros dos restantes campos obrigatórios.
      expect(find.text('Start date and time are required'), findsOneWidget);
      expect(find.text('Location is required'), findsOneWidget);
    });
  });
}
