import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolv/data.dart';
import 'package:resolv/directory.dart';
import 'package:resolv/main.dart';

void main() {
  testWidgets('Liga a chave pela tela e atualiza a Vitrine', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 870);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = AppData();
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Serviços'));
    await tester.pumpAndSettle();
    final configure = find.text('Configurar meu perfil');
    await tester.ensureVisible(configure);
    await tester.pumpAndSettle();
    await tester.tap(configure);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Quero oferecer serviços'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar preferências'));
    await tester.pumpAndSettle();
    expect(data.me.professional, isFalse);
    final tag = find.widgetWithText(FilterChip, 'Hidráulica');
    await tester.ensureVisible(tag);
    await tester.pumpAndSettle();
    await tester.tap(tag);
    await tester.tap(find.text('Salvar preferências'));
    await tester.pumpAndSettle();
    expect(data.me.professional, isTrue);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Vitrine'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), data.me.name);
    await tester.pumpAndSettle();
    expect(find.text(data.me.name), findsWidgets);
    expect(find.text('Ainda sem avaliações'), findsOneWidget);
  });

  testWidgets(
    'Recupera o mural anterior e mantém as preferências ao pausar os serviços',
    (tester) async {
      final existing = Post(
        'anterior',
        'u0',
        'Meu pedido anterior',
        'Descrição',
        adviceTag,
        DateTime(2026, 11, 16),
      );
      String? snapshot = jsonEncode({
        'version': 1,
        'user': 'u0',
        'posts': [existing.toJson()],
      });
      const storage = MethodChannel('resolv/storage');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(storage, (call) async {
        if (call.method == 'write') snapshot = call.arguments as String;
        return call.method == 'read' ? snapshot : null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(storage, null));
      final data = AppData();
      await data.load();
      expect(data.post('anterior')?.title, existing.title);
      expect(data.me.professional, isFalse);
      data.setProfessional(
        true,
        tags: ['Costura', 'Fotografia'],
        serviceAreas: ['Bela Vista'],
      );
      expect(
        serviceDirectory(data).any((p) => p.person.id == data.currentId),
        isTrue,
      );
      data.setProfessional(false);
      await data.saved;
      final after = AppData();
      await after.load();
      expect(after.me.professional, isFalse);
      expect(after.me.tags, containsAll(['Costura', 'Fotografia']));
      expect(after.me.areas, contains('Bela Vista'));
      expect(after.post('anterior'), isNotNull);
      expect(
        serviceDirectory(after).any((p) => p.person.id == after.currentId),
        isFalse,
      );
    },
  );

  testWidgets('Abre o pedido compatível de outro morador no Mural', (
    tester,
  ) async {
    final data = AppData();
    data.setProfessional(
      true,
      tags: ['Pequenos reparos'],
      serviceAreas: ['Centro'],
    );
    data.addPost(
      'Meu próprio pedido',
      'Excluir da lista de serviços',
      'Pequenos reparos',
    );
    final available = serviceRequests(data);
    expect(available, isNotEmpty);
    expect(
      available.every(
        (p) =>
            !p.resolved &&
            p.authorId != data.currentId &&
            p.tag == 'Pequenos reparos' &&
            data.person(p.authorId).area == 'Centro',
      ),
      isTrue,
    );
    await tester.pumpWidget(ResolvApp(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Serviços'));
    await tester.pumpAndSettle();
    final post = find.text(available.first.title);
    await tester.ensureVisible(post);
    await tester.tap(post);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.text(available.first.title), findsWidgets);
    expect(find.text('Comentários'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
