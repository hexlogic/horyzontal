import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/secure_store.dart';
import 'package:horyzontal/features/security/lock.dart';
import 'package:horyzontal/features/security/lock_screen.dart';
import 'package:horyzontal/features/security/pin_store.dart';

import 'helpers.dart';

void main() {
  test('locks only after the configured time in background', () {
    final c = ProviderContainer(overrides: [initialPinEnabledProvider.overrideWithValue(true)]);
    addTearDown(c.dispose);
    final lock = c.read(lockProvider.notifier);
    lock.unlock();
    final t = DateTime(2026);
    lock.wentToBackground(t);
    lock.cameBack(t.add(const Duration(seconds: 10)), const Duration(seconds: 30));
    expect(c.read(lockProvider).locked, isFalse);
    lock.wentToBackground(t);
    lock.cameBack(t.add(const Duration(seconds: 31)), const Duration(seconds: 30));
    expect(c.read(lockProvider).locked, isTrue);

    lock.unlock();
    lock.authenticating = true; // biometric sheet
    lock.wentToBackground(t);
    lock.cameBack(t.add(const Duration(minutes: 5)), Duration.zero);
    expect(c.read(lockProvider).locked, isFalse);
  });

  testWidgets('lock screen covers the app until the right PIN', (tester) async {
    final store = MemorySecureStore();
    await PinStore(store, iterations: 10).setPin('123456');
    await tester.pumpWidget(
      testApp(
        const LockGate(child: Scaffold(body: Text('secret'))),
        store: store,
        pinEnabled: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Введіть PIN-код'), findsOneWidget);

    Future<void> enter(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }

    await enter('111111');
    expect(find.text('Невірний PIN-код'), findsOneWidget);
    expect(find.text('Введіть PIN-код'), findsOneWidget);

    await enter('123456');
    expect(find.text('Введіть PIN-код'), findsNothing);
    expect(find.text('secret'), findsOneWidget);
  });
}
