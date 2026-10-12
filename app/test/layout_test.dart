import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/router.dart';

import 'helpers.dart';

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(testApp(null, router: buildRouter(initialLocation: '/tasks')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone width: bottom navigation bar', (tester) async {
    await _pumpAt(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Сонце й Місяць'), findsOneWidget);
  });

  testWidgets('tablet width: navigation rail and pages of readable width', (tester) async {
    await _pumpAt(tester, const Size(1200, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final tile = tester.getSize(find.ancestor(of: find.text('Сонце й Місяць'), matching: find.byType(ListTile)));
    expect(tile.width, lessThanOrEqualTo(720));
    await tester.tap(find.text('Налаштування'));
    await tester.pumpAndSettle();
    expect(find.text('Джерела мапи'), findsOneWidget);
  });
}
