import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolv/data.dart';
import 'package:resolv/main.dart';

void main() {
  testWidgets('O histórico demo abre e o envio não gera resposta automática', (
    tester,
  ) async {
    final data = AppData();
    final before = data.conversation('u5')!.messages.length;
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Conversas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lia Ramos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Histórico de exemplo'), findsOneWidget);
    expect(data.unreadChats, 0);
    await tester.enterText(
      find.byType(TextField),
      '  Posso levar as peças às 16h?  ',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Enviar mensagem'));
    await tester.pumpAndSettle();
    final messages = data.conversation('u5')!.messages;
    expect(messages.length, before + 1);
    expect(messages.last.body, 'Posso levar as peças às 16h?');
    expect(messages.last.outgoing, isTrue);
    expect(messages.last.example, isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(data.inbox.first.peerId, 'u5');
    expect(find.text('Você: Posso levar as peças às 16h?'), findsOneWidget);
  });

  testWidgets(
    'Associa cada conversa ao pedido certo e recupera as mensagens no aparelho',
    (tester) async {
      const channel = MethodChannel('resolv/storage');
      final messenger = tester.binding.defaultBinaryMessenger;
      String? saved = '{"version":1,"user":"u0"}';
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') saved = call.arguments as String;
        return call.method == 'read' ? saved : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final data = AppData();
      await data.load();
      final demoCount = data.inbox.length;
      final post = data.posts.first;
      data.sendMessage(post.authorId, '  ', postId: post.id);
      expect(data.inbox.length, demoCount);
      data.sendMessage(
        post.authorId,
        'Consigo ver a porta amanhã.',
        postId: post.id,
      );
      data.sendMessage(post.authorId, 'À tarde fica bom?', postId: post.id);
      expect(data.inbox.length, demoCount + 1);
      expect(() => data.sendMessage(data.currentId, 'Oi'), throwsArgumentError);
      expect(
        () => data.sendMessage('u1', 'Oi', postId: post.id),
        throwsArgumentError,
      );
      await data.saved;
      final restored = AppData();
      await restored.load();
      expect(restored.inbox.length, demoCount + 1);
      expect(
        restored
            .conversation(post.authorId, postId: post.id)!
            .messages
            .map((m) => m.body),
        ['Consigo ver a porta amanhã.', 'À tarde fica bom?'],
      );
      expect(
        restored.conversation('u1')!.messages.every((m) => m.example),
        isTrue,
      );
    },
  );

  testWidgets('Vitrine e pedido abrem a conversa com o destinatário correto', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 870);
    addTearDown(tester.view.reset);
    final data = AppData();
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Vitrine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aulas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Ribeiro'));
    await tester.pumpAndSettle();
    final chat = find.widgetWithText(FilledButton, 'Conversar');
    await tester.ensureVisible(chat);
    await tester.pumpAndSettle();
    await tester.tap(chat);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ana Ribeiro'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Mural'));
    await tester.pumpAndSettle();
    final first = data.posts.first;
    await tester.tap(find.text(first.title));
    await tester.pumpAndSettle();
    final contact = find.text('Conversar com o morador');
    await tester.ensureVisible(contact);
    await tester.pumpAndSettle();
    await tester.tap(contact);
    await tester.pumpAndSettle();
    expect(find.text('Pedido · ${first.title}'), findsOneWidget);
    expect(
      find.widgetWithText(AppBar, data.person(first.authorId).name),
      findsOneWidget,
    );
  });
}
