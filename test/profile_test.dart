import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolv/data.dart';
import 'package:resolv/directory.dart';
import 'package:resolv/main.dart';

void main() {
  testWidgets('Edita o perfil e volta do próprio pedido sem perder a aba', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 870);
    addTearDown(tester.view.reset);
    final data = AppData();
    final post = data.addPost(
      'Minha torneira',
      'Preciso de ajuda',
      'Hidráulica',
    );
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Júlia Alves');
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();
    expect(data.me.name, 'Júlia Alves');
    expect(find.text('Júlia Alves'), findsOneWidget);
    await tester.tap(find.text(post.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar ao Perfil'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  testWidgets(
    'Persiste dados e avalia apenas uma vez o atendimento concluído',
    (tester) async {
      const channel = MethodChannel('resolv/storage');
      final messenger = tester.binding.defaultBinaryMessenger;
      String? stored;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'write') stored = call.arguments as String;
        return call.method == 'read' ? stored : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final data = AppData();
      final initialArea = data.me.area;
      final post = data.addPost(
        'Montar a mesa',
        'Ela já chegou.',
        'Montagem de móveis',
      );
      final provider = serviceDirectory(data)
          .firstWhere((p) => p.tags.contains('Montagem de móveis'));
      expect(
        () => data.reviewService(post.id, provider.person.id, 4, ''),
        throwsStateError,
      );
      data.resolve(post.id);
      data.reviewService(post.id, provider.person.id, 4, 'Chegou no horário.');
      expect(
        () => data.reviewService(post.id, provider.person.id, 5, ''),
        throwsStateError,
      );
      data.editProfile('Júlia Alves', 'Vila Nova', 'Faço ajustes em roupas.');
      await data.saved;
      final restored = AppData();
      await restored.load();
      expect(restored.me.bio, 'Faço ajustes em roupas.');
      expect(restored.me.area, 'Vila Nova');
      expect(restored.post(post.id)!.area, initialArea);
      expect(restored.reviews.single.note, 'Chegou no horário.');
      expect(
        serviceDirectory(restored)
            .firstWhere((p) => p.person.id == provider.person.id)
            .reviewCount,
        provider.reviewCount + 1,
      );
    },
  );
}
