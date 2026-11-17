import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolv/data.dart';
import 'package:resolv/main.dart';

void main() {
  testWidgets('O Mural abre e permite filtrar os pedidos', (tester) async {
    final data = AppData();
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    expect(find.text('Mural'), findsWidgets);
    expect(find.text(data.posts.first.title), findsOneWidget);
    await tester.tap(find.text('Resolvidos').first);
    await tester.pumpAndSettle();
    expect(
      find.text(data.posts.firstWhere((p) => p.resolved).title),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salva o pedido e os comentários ao reabrir', (tester) async {
    const storage = MethodChannel('resolv/storage');
    final messenger = tester.binding.defaultBinaryMessenger;
    String? snapshot;
    messenger.setMockMethodCallHandler(storage, (call) async {
      if (call.method == 'write') snapshot = call.arguments as String;
      return call.method == 'read' ? snapshot : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(storage, null));
    final data = AppData();
    final post = data.addPost(
      'Conserto de porta',
      'A maçaneta soltou.',
      adviceTag,
    );
    data.comment(post.id, 'Consegui uma indicação.');
    data.changeTag(post.id, 'Pequenos reparos');
    data.resolve(post.id);
    await data.saved;
    final restored = AppData();
    await restored.load();
    final saved = restored.post(post.id)!;
    expect(saved.tag, 'Pequenos reparos');
    expect(saved.comments.single.text, 'Consegui uma indicação.');
    expect(saved.resolved, isTrue);
  });
}
