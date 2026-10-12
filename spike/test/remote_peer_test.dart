import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal_spike/transfer/protocol.dart';
import 'package:horyzontal_spike/transfer/secure_channel.dart';
import 'package:horyzontal_spike/transfer/wifi_link.dart';

/// Desktop peer for a host running on a device, emulator or simulator:
///
///   INVITE='{"v":1,...}' flutter test test/remote_peer_test.dart
///
/// Skipped when INVITE is not set.
void main() {
  final raw = Platform.environment['INVITE'];
  test('transfer with a remote host', () async {
    final inv = Invite.decode(raw!);
    final socket = await connectAny(inv.addresses, inv.port, deadline: const Duration(seconds: 10));
    final ch = SecureChannel(socket, inv.key, isHost: false);
    await sendHello(ch);
    final tmp = await Directory.systemTemp.createTemp('hrz');
    var last = DateTime.now();
    void progress(int done, int total) {
      if (DateTime.now().difference(last).inMilliseconds > 1000) {
        last = DateTime.now();
        // ignore: avoid_print
        print('${(done / 1e6).toStringAsFixed(1)} / ${(total / 1e6).toStringAsFixed(1)} MB');
      }
    }

    final stats = inv.hostSends
        ? await receiveFile(ch, tmp, progress)
        : await sendFile(ch, await makeTestFile(tmp, 10), progress);
    // ignore: avoid_print
    print(stats);
    expect(stats.ok, isTrue);
    await ch.close();
  }, skip: raw == null ? 'INVITE not set' : false, timeout: const Timeout(Duration(minutes: 3)));
}
