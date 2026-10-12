import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/core/data/repository.dart';
import 'package:horyzontal/features/objects/feature_editor_page.dart';
import 'package:horyzontal/features/objects/feature_sheet.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import 'helpers.dart';

void main() {
  const square = [
    Geodetic(50.0, 30.0),
    Geodetic(50.0, 30.014),
    Geodetic(50.009, 30.014),
    Geodetic(50.009, 30.0),
  ];

  testWidgets('a drawn polygon is saved and its card shows the area', (tester) async {
    bool? saved;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => saved = await context.push<bool>('/shape', extra: square),
                child: const Text('draw'),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'shape',
              builder: (_, s) => FeatureEditorPage(
                kind: FeatureKind.polygon,
                vertices: s.extra! as List<Geodetic>,
              ),
            ),
            GoRoute(
              path: 'object/:id',
              builder: (_, s) => FeaturePage(id: s.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(testApp(null, router: router));
    await tester.tap(find.text('draw'));
    await settle();
    expect(find.text('Новий полігон'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Поле');
    await tester.tap(find.text('Зберегти'));
    await settle();
    expect(saved, isTrue);

    final container = ProviderScope.containerOf(tester.element(find.text('draw')));
    final features = await tester.runAsync(
      () => container.read(repositoryProvider).watchFeatures().first,
    );
    final f = features!.single;
    expect(f.kind, FeatureKind.polygon);
    expect(f.name, 'Поле');
    expect(f.vertices, hasLength(4));

    router.push('/object/${f.id}');
    await settle();
    expect(find.text('Площа'), findsOneWidget);
    expect(find.textContaining('га'), findsOneWidget); // about 100 ha
    expect(find.text('Периметр'), findsOneWidget);

    // Drift closes its stream queries on a zero timer after the tree goes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
