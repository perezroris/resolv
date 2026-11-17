import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolv/data.dart';
import 'package:resolv/directory.dart';
import 'package:resolv/main.dart';

void main() {
  final data = AppData();
  final profiles = serviceDirectory(data);
  test(
    'Prioriza o bairro, depois amplia a busca só até encontrar quem atenda',
    () {
      expect(profiles.map((p) => p.person.id).toSet().length, 36);
      final local = findProviders(profiles, area: 'Centro', query: 'faxina');
      expect(local, isNotEmpty);
      expect(local.every((p) => p.person.area == 'Centro'), isTrue);
      final nearby = findProviders(
        profiles,
        area: 'Centro',
        tag: 'Aulas particulares',
      );
      expect(nearby.map((p) => p.person.name), contains('Ana Ribeiro'));
      expect(
        nearby.every(
          (p) =>
              p.serviceAreas.contains('Centro') &&
              neighborhoodDistance('Centro', p.person.area) == 1,
        ),
        isTrue,
      );
      expect(
        findProviders(
          profiles,
          area: 'Centro',
          tag: 'Conserto de eletrodomésticos',
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Aplica uma categoria, exibe o perfil e permite criar um pedido no Mural',
    (tester) async {
      await tester.pumpWidget(ResolvApp(data: AppData()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vitrine').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aulas'));
      await tester.pumpAndSettle();
      expect(find.text('Nos bairros próximos'), findsOneWidget);
      await tester.tap(find.text('Ana Ribeiro'));
      await tester.pumpAndSettle();
      expect(find.text('Bairros onde atende'), findsOneWidget);
      await tester.tap(find.text('Categorias'));
      await tester.pumpAndSettle();
      final missing = find.text('Conserto de eletrodomésticos');
      await tester.fling(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(ListView),
        ),
        const Offset(0, -650),
        1200,
      );
      await tester.pumpAndSettle();
      await tester.tap(missing);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar pedido no Mural'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Conserto de eletrodomésticos'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
