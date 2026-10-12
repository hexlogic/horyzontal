import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/exchange/transfer/protocol.dart';
import 'package:horyzontal/features/exchange/transfer/secure_channel.dart';
import 'package:horyzontal/features/exchange/transfer/transport.dart';
import 'package:horyzontal/features/exchange/transfer/wifi_link.dart';

void main() {
  Future<(SecureChannel, SecureChannel)> pair(List<int> hostKey, List<int> clientKey) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = server.first;
    final client = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
    final host = await accepted;
    await server.close();
    return (
      SecureChannel(SocketTransport(host), hostKey, isHost: true),
      SecureChannel(SocketTransport(client), clientKey, isHost: false),
    );
  }

  test('layers go across and the checksum is confirmed', () async {
    final key = Invite.newKey();
    final (host, client) = await pair(key, key);
    final payload = Uint8List.fromList(List.generate(700000, (i) => i * 31 % 251));
    final sender = () async {
      await expectHello(host);
      return sendLayers(host, const [LayerSummary('Розвідка', 12)], payload);
    }();
    await sendHello(client);
    final got = await receiveLayers(client);
    expect(await sender, isTrue);
    expect(got!.$1.layers.single.name, 'Розвідка');
    expect(got.$1.layers.single.objects, 12);
    expect(got.$2, payload);
    await host.close();
    await client.close();
  });

  test('a client without the key is rejected before anything is sent', () async {
    final (host, client) = await pair(Invite.newKey(), Invite.newKey());
    await sendHello(client);
    await expectLater(expectHello(host), throwsA(anything));
    await host.close();
    await client.close();
  });

  test('invite round trip and junk', () {
    final inv = Invite(
      mode: InviteMode.hotspot,
      ssid: 'AndroidShare_1234',
      psk: 'abcd1234',
      security: 2,
      addresses: ['10.85.97.1'],
      port: 40123,
      key: Invite.newKey(),
      hostSends: true,
    );
    final back = Invite.tryDecode(inv.encode())!;
    expect(back.mode, InviteMode.hotspot);
    expect(back.ssid, inv.ssid);
    expect(back.addresses, inv.addresses);
    expect(back.key, inv.key);
    expect(back.hostSends, isTrue);
    final mpc = Invite.tryDecode(
        Invite(mode: InviteMode.multipeer, token: Invite.newToken(), key: Invite.newKey(), hostSends: false)
            .encode())!;
    expect(mpc.token, hasLength(10));
    expect(Invite.tryDecode('{"v":1}'), isNull);
    expect(Invite.tryDecode('not json'), isNull);
  });
}
