import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'secure_channel.dart';

/// Spike transfer protocol, on top of [SecureChannel]:
///   client -> HELLO (proves it holds the key before the host sends anything)
///   sender -> OFFER {name, size, sha256}, CHUNK..., DONE
///   receiver -> RESULT {ok, sha256}
abstract final class Msg {
  static const hello = 0;
  static const offer = 1;
  static const chunk = 2;
  static const done = 3;
  static const result = 4;
}

const helloText = 'HRZ-SPIKE-1';
const chunkSize = 256 * 1024;

typedef Progress = void Function(int done, int total);

class TransferStats {
  TransferStats(this.bytes, this.elapsed, this.ok, this.sha256);

  final int bytes;
  final Duration elapsed;
  final bool ok;
  final String sha256;

  double get mbPerSec => bytes / 1e6 / (elapsed.inMicroseconds / 1e6);

  @override
  String toString() => '${ok ? 'OK' : 'ПОМИЛКА'}: ${(bytes / 1e6).toStringAsFixed(1)} МБ '
      'за ${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)} с, '
      '${mbPerSec.toStringAsFixed(2)} МБ/с, sha256 ${sha256.substring(0, 12)}…';
}

Future<void> sendHello(SecureChannel ch) => ch.send(Msg.hello, utf8.encode(helloText));

Future<void> expectHello(SecureChannel ch) async {
  final m = await ch.receive();
  if (m.type != Msg.hello || utf8.decode(m.payload) != helloText) {
    throw const FormatException('unexpected hello');
  }
}

/// Random test payload, so the spike needs no real data on the phone.
Future<File> makeTestFile(Directory dir, int megabytes) async {
  final file = File('${dir.path}/test-${megabytes}mb.bin');
  final sink = file.openWrite();
  final rnd = Random();
  for (var i = 0; i < megabytes; i++) {
    final words = Uint32List(1 << 18);
    for (var j = 0; j < words.length; j++) {
      words[j] = rnd.nextInt(1 << 32);
    }
    sink.add(words.buffer.asUint8List());
  }
  await sink.close();
  return file;
}

Future<TransferStats> sendFile(SecureChannel ch, File file, Progress onProgress) async {
  final size = await file.length();
  final digest = (await sha256.bind(file.openRead()).first).toString();
  final sw = Stopwatch()..start();
  await ch.send(Msg.offer, utf8.encode(jsonEncode({
    'name': file.uri.pathSegments.last,
    'size': size,
    'sha256': digest,
  })));
  var sent = 0;
  final raf = await file.open();
  try {
    while (sent < size) {
      final block = await raf.read(chunkSize);
      await ch.send(Msg.chunk, block);
      sent += block.length;
      onProgress(sent, size);
    }
  } finally {
    await raf.close();
  }
  await ch.send(Msg.done, const []);
  final res = await ch.receive();
  if (res.type != Msg.result) throw const FormatException('expected result');
  final body = jsonDecode(utf8.decode(res.payload)) as Map<String, dynamic>;
  return TransferStats(size, sw.elapsed, body['ok'] == true && body['sha256'] == digest, digest);
}

Future<TransferStats> receiveFile(SecureChannel ch, Directory dir, Progress onProgress) async {
  final offer = await ch.receive();
  if (offer.type != Msg.offer) throw const FormatException('expected offer');
  final meta = jsonDecode(utf8.decode(offer.payload)) as Map<String, dynamic>;
  final size = meta['size'] as int;
  final sw = Stopwatch()..start();

  // The name comes from the peer: keep only the last path segment.
  final name = (meta['name'] as String).split(RegExp(r'[/\\]')).last;
  final sink = File('${dir.path}/received-$name').openWrite();
  final hashOut = _DigestSink();
  final hasher = sha256.startChunkedConversion(hashOut);
  var got = 0;
  while (true) {
    final m = await ch.receive();
    if (m.type == Msg.done) break;
    if (m.type != Msg.chunk) throw const FormatException('expected chunk');
    sink.add(m.payload);
    hasher.add(m.payload);
    got += m.payload.length;
    onProgress(got, size);
  }
  await sink.close();
  hasher.close();
  final digest = hashOut.value.toString();
  final ok = got == size && digest == meta['sha256'];
  await ch.send(Msg.result, utf8.encode(jsonEncode({'ok': ok, 'sha256': digest})));
  return TransferStats(got, sw.elapsed, ok, digest);
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
