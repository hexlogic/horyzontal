import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/secure_store.dart';
import 'package:horyzontal/features/security/pin_store.dart';

void main() {
  late MemorySecureStore store;
  late DateTime now;
  late PinStore pins;

  setUp(() {
    store = MemorySecureStore();
    now = DateTime(2026, 10, 12, 12);
    pins = PinStore(store, iterations: 10, clock: () => now);
  });

  test('set, verify, clear', () async {
    expect(await pins.hasPin(), isFalse);
    await pins.setPin('123456');
    expect(await pins.hasPin(), isTrue);
    expect(store.values.values.join(), isNot(contains('123456')));
    expect(await pins.verify('123456'), isA<PinOk>());
    expect(await pins.verify('654321'), isA<PinWrong>());
    await pins.clear();
    expect(await pins.hasPin(), isFalse);
  });

  test('rejects malformed PINs', () {
    expect(() => pins.setPin('12345'), throwsArgumentError);
    expect(() => pins.setPin('abcdef'), throwsArgumentError);
  });

  test('blocks after five failures, doubling the wait, survives restart', () async {
    await pins.setPin('123456');
    for (var i = 0; i < 4; i++) {
      expect(await pins.verify('000000'), isA<PinWrong>());
    }
    final fifth = await pins.verify('000000');
    expect(fifth, isA<PinBlocked>());
    expect((fifth as PinBlocked).until, now.add(const Duration(seconds: 30)));

    // Even the right PIN is refused while blocked, also by a new instance.
    final restarted = PinStore(store, iterations: 10, clock: () => now);
    expect(await restarted.verify('123456'), isA<PinBlocked>());

    now = now.add(const Duration(seconds: 31));
    final sixth = await restarted.verify('000000');
    expect((sixth as PinBlocked).until, now.add(const Duration(seconds: 60)));

    now = now.add(const Duration(seconds: 61));
    expect(await restarted.verify('123456'), isA<PinOk>());
    expect(await restarted.blockedUntil(), isNull);
    expect(await restarted.verify('000000'), isA<PinWrong>());
  });
}
