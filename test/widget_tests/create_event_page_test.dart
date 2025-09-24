import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Ajusta estes imports para os teus paths reais:
import 'package:app/features/create_event/presentation/pages/create_event_page.dart';
import 'package:app/shared/components/dialogs/confirm_event_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) => MaterialApp(home: child);

  group('CreateEventPage – só prossegue com nome + grupo', () {
    testWidgets('Sem nome e grupo: mostra erros e NÃO abre confirmação', (
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

      // Erros devem aparecer
      expect(find.text('Event name is required'), findsOneWidget);
      expect(find.text('Please select a group'), findsOneWidget);

      // Confirm dialog NÃO deve abrir
      expect(find.byType(ConfirmEventBottomSheet), findsNothing);
    });

    testWidgets('Com nome e grupo: abre ConfirmEventBottomSheet', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const CreateEventPage()));

      // 1) Abrir editor do nome (tap no texto "Add Event Name" abre o bottom sheet)
      //   Dica: a GestureDetector está no container que contém este texto, o tap no texto propaga.
      final nameTapTarget = find.text('Add Event Name');
      expect(nameTapTarget, findsOneWidget);
      await tester.tap(nameTapTarget);
      await tester.pumpAndSettle(); // abre o bottom sheet do nome

      // 2) Preencher nome no TextField com key fornecida pelo EventGroupSelector
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

      // 3) Selecionar um grupo (usa a key do botão de grupo)
      final groupBtn = find.byKey(const Key('createEvent:groupButton'));
      expect(
        groupBtn,
        findsOneWidget,
        reason:
            'A groupButtonKey tem de estar no GestureDetector que chama onGroupPressed',
      );
      await tester.tap(groupBtn);
      await tester.pumpAndSettle(); // abre BottomSheet de grupos

      // Escolher "Os Bros" (vem de _getMockGroups)
      await tester.tap(find.text('Os Bros'));
      await tester.pumpAndSettle(); // fecha sheet

      // 4) Prosseguir
      final continueBtn = find.byKey(const Key('continue_button'));
      await tester.scrollUntilVisible(
        continueBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Deve abrir o ConfirmEventBottomSheet
      expect(find.byType(ConfirmEventBottomSheet), findsOneWidget);

      // E não devem existir erros de validação
      expect(find.text('Event name is required'), findsNothing);
      expect(find.text('Please select a group'), findsNothing);
    });
  });
}
