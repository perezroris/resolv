import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolv/data.dart';
import 'package:resolv/job_summary.dart';
import 'package:resolv/main.dart';

void main() {
  test('Lê valores em reais e preserva os centavos e a unidade', () {
    for (final value in ['1.200,50', '1200,50', '1200.50', ' 1200,5 ']) {
      final price = Estimate.fromInput(value, PriceUnit.day)!;
      expect(price.cents, 120050);
      expect(price.label, r'R$ 1.200,50 por diária');
    }
    expect(Estimate.parseCents('1.200'), 120000);
    expect(Estimate.parseCents('80'), 8000);
    for (final invalid in ['', '0', '-12', '70,123', '2.34,12', 'R', '1e2']) {
      expect(Estimate.parseCents(invalid), isNull);
    }
  });

  testWidgets(
    'O orçamento do Mural e as propostas de cada conversa são independentes',
    (tester) async {
      const channel = MethodChannel('resolv/storage');
      final messenger = tester.binding.defaultBinaryMessenger;
      String? snapshot;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') snapshot = call.arguments as String;
        return call.method == 'read' ? snapshot : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final data = AppData();
      final post = data.addPost(
        'Instalar estante',
        'Montar duas prateleiras.',
        adviceTag,
        estimate: const Estimate(9000, PriceUnit.service),
      );
      final proposal = JobSummary(
        post.title,
        post.body,
        const Estimate(7500, PriceUnit.visit),
      );
      data.updateJobSummary('u2', proposal, postId: post.id);
      data.updateJobSummary('u2', proposal, postId: post.id);
      expect(
        data.conversation('u2', postId: post.id)!.messages.single.body,
        contains(r'Estimativa anterior: R$ 90,00 pelo serviço'),
      );
      data.sendMessage('u2', 'Pode ser às 15h?', postId: post.id);
      await data.saved;
      final restored = AppData();
      await restored.load();
      expect(
        restored.jobSummary('u2', postId: post.id).priceLabel,
        r'R$ 75,00 por visita',
      );
      expect(
        restored.jobSummary('u3', postId: post.id).priceLabel,
        r'R$ 90,00 pelo serviço',
      );
      expect(restored.jobSummary('u2', postId: post.id).description, post.body);
      restored.updateJobSummary(
        'u2',
        JobSummary(post.title, post.body),
        postId: post.id,
      );
      expect(
        restored.jobSummary('u2', postId: post.id).priceLabel,
        'A combinar',
      );
      expect(restored.post(post.id)!.estimate!.cents, 9000);
      await restored.saved;
    },
  );

  testWidgets('Envia contraproposta pelo chat e guarda a estimativa anterior', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final data = AppData();
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Conversas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lia Ramos'));
    await tester.pumpAndSettle();
    expect(find.text('Barra de duas calças'), findsOneWidget);
    expect(find.text(r'Estimativa · R$ 35,00 por peça'), findsOneWidget);
    final previousCount = data.conversation('u5')!.messages.length;
    await tester.tap(find.byTooltip('Editar serviço e propor valor'));
    await tester.pumpAndSettle();
    final amount = find.widgetWithText(
      TextFormField,
      'Valor estimado (opcional)',
    );
    await tester.enterText(amount, '30,00');
    await tester.ensureVisible(find.text('Enviar proposta'));
    await tester.tap(find.text('Enviar proposta'));
    await tester.pumpAndSettle();
    expect(find.text(r'Estimativa · R$ 30,00 por peça'), findsOneWidget);
    expect(
      find.textContaining(r'Estimativa anterior: R$ 35,00 por peça'),
      findsOneWidget,
    );
    expect(data.conversation('u5')!.messages.length, previousCount + 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Publica pedido com valor informado no formulário do Mural', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 870);
    addTearDown(tester.view.reset);
    final data = AppData();
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedir ajuda'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Faxina de sábado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição'),
      'Limpar sala e cozinha.',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(adviceTag).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Informar valor estimado'));
    await tester.tap(find.text('Informar valor estimado'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor estimado (opcional)'),
      '150',
    );
    final units = find.byType(DropdownButtonFormField<PriceUnit>);
    await tester.ensureVisible(units);
    await tester.tap(units);
    await tester.pumpAndSettle();
    await tester.tap(find.text('por diária').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publicar'));
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    final post = data.posts.first;
    expect(post.title, 'Faxina de sábado');
    expect(
      data.jobSummary('u8', postId: post.id).priceLabel,
      r'R$ 150,00 por diária',
    );
    expect(tester.takeException(), isNull);
  });
}
