import 'package:atlas_e0/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('salva sessões e exibe painel do desenvolvedor', (tester) async {
    await tester.pumpWidget(const AtlasE0App());
    await tester.pumpAndSettle();

    expect(find.text('Toda decisão revela alguma coisa.'), findsOneWidget);

    await _completeZeroRoomSession(tester);
    expect(find.text('O que observamos'), findsOneWidget);
    expect(find.text('5 interações registradas nesta sessão.'), findsOneWidget);

    await tester.tap(find.text('Recomeçar'));
    await tester.pumpAndSettle();
    await _completeZeroRoomSession(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const AtlasE0App());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dev'));
    await tester.pumpAndSettle();

    expect(find.text('Painel Dev'), findsOneWidget);
    expect(find.text('Sessões'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Últimas sessões'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();

    expect(find.text('Detalhe da sessão'), findsOneWidget);
    expect(find.text('Linha do tempo'), findsOneWidget);
    expect(find.textContaining('toques no elemento'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Visualizar JSON'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Visualizar JSON'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sessionId'), findsOneWidget);
  });
}

Future<void> _completeZeroRoomSession(WidgetTester tester) async {
  if (find.text('Começar').evaluate().isNotEmpty) {
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
  }

  expect(find.text('Sala Zero'), findsOneWidget);

  await tester.tap(find.text('Porta fechada'));
  await tester.pumpAndSettle();
  expect(find.textContaining('A porta não cede'), findsOneWidget);

  await tester.tap(find.text('Objeto central'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Janela distante'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Gaveta da mesa'));
  await tester.pumpAndSettle();

  expect(find.text('Porta pronta: toque nela para encerrar.'), findsOneWidget);

  await tester.tap(find.text('Porta fechada'));
  await tester.pumpAndSettle();

  expect(find.text('Sair da sala'), findsOneWidget);

  await tester.tap(find.text('Sair da sala'));
  await tester.pumpAndSettle();
}
