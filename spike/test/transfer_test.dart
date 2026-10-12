import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal_spike/transfer/protocol.dart';
import 'package:horyzontal_spike/transfer/secure_channel.dart';
import 'package:horyzontal_spike/transfer/wifi_link.dart';

Future<(SecureChannel, SecureChannel)> _pair(List<int> hostKey, List<int> clientKey) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final accepted = server.first;
  final client = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
  final host = await accepted;
  await server.close();
  return (
    SecureChannel(host, hostKey, isHost: true),
    SecureChannel(client, clientKey, isHost: false),
  );
}

void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('hrz'));
  tearDown(() => tmp.delete(recursive: true));

  test('file goes host -> client intact', () async {
    final key = Invite.newKey();
    final (host, client) = await _pair(key, key);
    final file = await makeTestFile(tmp, 3);
    final recvDir = await Directory('${tmp.path}/in').create();

    await sendHello(client);
    await expectHello(host);
    final results = await Future.wait([
      sendFile(host, file, (_, _) {}),
      receiveFile(client, recvDir, (_, _) {}),
    ]);
    expect(results.every((r) => r.ok), isTrue);
    expect(results[1].bytes, 3 << 20);
    final got = File('${recvDir.path}/received-test-3mb.bin');
    expect(await got.readAsBytes(), await file.readAsBytes());
  });

  test('wrong key is rejected at hello', () async {
    final (host, client) = await _pair(Invite.newKey(), Invite.newKey());
    await sendHello(client);
    await expectLater(expectHello(host), throwsA(isA<SecretBoxAuthenticationError>()));
  });

  test('invite survives the QR round trip', () {
    final inv = Invite(
      ssid: 'AndroidShare_1234',
      psk: 'p4ss word"\'',
      security: 2,
      addresses: ['192.168.49.1', '10.0.0.5'],
      port: 40123,
      key: Invite.newKey(),
      hostSends: false,
    );
    final back = Invite.decode(inv.encode());
    expect(back.ssid, inv.ssid);
    expect(back.psk, inv.psk);
    expect(back.key, inv.key);
    expect(back.addresses, inv.addresses);
    expect(back.hostSends, isFalse);
    expect(inv.encode().length, lessThan(300)); // keeps the QR small and easy to scan
  });
}
