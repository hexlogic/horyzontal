import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'secure_channel.dart';

/// Layer transfer on top of [SecureChannel]:
///   client -> HELLO (proves it holds the key before the host says anything)
///   sender -> OFFER {layers: [{name, objects}], bytes, sha256}, CHUNK..., DONE
///   receiver -> RESULT {ok}
/// The payload is a .hrz export of the chosen layers.
abstract final class Msg {
  static const hello = 0;
  static const offer = 1;
  static const chunk = 2;
  static const done = 3;
  static const result = 4;
}

const helloText = 'HRZ-LAYERS-1';
const _chunkSize = 256 * 1024;
const maxPayload = 64 * 1024 * 1024;

class LayerSummary {
  const LayerSummary(this.name, this.objects);
  final String name;
  final int objects;
}

class Offer {
  const Offer(this.layers, this.bytes, this.sha256);
  final List<LayerSummary> layers;
  final int bytes;
  final String sha256;

  List<int> encode() => utf8.encode(jsonEncode({
        'layers': [for (final l in layers) {'name': l.name, 'objects': l.objects}],
        'bytes': bytes,
        'sha256': sha256,
      }));

  static Offer decode(List<int> raw) {
    final j = jsonDecode(utf8.decode(raw)) as Map<String, Object?>;
    return Offer(
      [
        for (final l in (j['layers']! as List<Object?>).cast<Map<String, Object?>>())
          LayerSummary(l['name']! as String, l['objects']! as int),
      ],
      j['bytes']! as int,
      j['sha256']! as String,
    );
  }
}

typedef Progress = void Function(int done, int total);

Future<void> sendHello(SecureChannel ch) => ch.send(Msg.hello, utf8.encode(helloText));

Future<void> expectHello(SecureChannel ch) async {
  final m = await ch.receive(timeout: const Duration(seconds: 30));
  if (m.type != Msg.hello || utf8.decode(m.payload) != helloText) {
    throw const FormatException('unexpected hello');
  }
}

/// Sends [payload]; returns whether the receiver confirmed the checksum.
Future<bool> sendLayers(SecureChannel ch, List<LayerSummary> layers, Uint8List payload,
    {Progress? onProgress}) async {
  final digest = sha256.convert(payload).toString();
  await ch.send(Msg.offer, Offer(layers, payload.length, digest).encode());
  for (var sent = 0; sent < payload.length; sent += _chunkSize) {
    final end = (sent + _chunkSize).clamp(0, payload.length);
    await ch.send(Msg.chunk, Uint8List.sublistView(payload, sent, end));
    onProgress?.call(end, payload.length);
  }
  await ch.send(Msg.done, const []);
  final res = await ch.receive();
  if (res.type != Msg.result) throw const FormatException('expected result');
  return (jsonDecode(utf8.decode(res.payload)) as Map<String, Object?>)['ok'] == true;
}

/// Receives an offer and its payload; null when the checksum fails.
Future<(Offer, Uint8List)?> receiveLayers(SecureChannel ch, {Progress? onProgress}) async {
  final m = await ch.receive();
  if (m.type != Msg.offer) throw const FormatException('expected offer');
  final offer = Offer.decode(m.payload);
  if (offer.bytes > maxPayload) throw const FormatException('payload too large');
  final data = BytesBuilder(copy: false);
  while (true) {
    final c = await ch.receive();
    if (c.type == Msg.done) break;
    if (c.type != Msg.chunk) throw const FormatException('expected chunk');
    data.add(c.payload);
    if (data.length > offer.bytes) throw const FormatException('payload larger than offered');
    onProgress?.call(data.length, offer.bytes);
  }
  final bytes = data.takeBytes();
  final ok = bytes.length == offer.bytes && sha256.convert(bytes).toString() == offer.sha256;
  await ch.send(Msg.result, utf8.encode(jsonEncode({'ok': ok})));
  return ok ? (offer, bytes) : null;
}
