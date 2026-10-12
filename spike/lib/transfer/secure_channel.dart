import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Length-prefixed AES-256-GCM frames over a TCP socket.
///
/// Wire format: `u32 BE length | ciphertext | 16-byte tag`. The first
/// plaintext byte is the message type. Nonces are never sent: each side uses
/// `direction (4 bytes) | counter (8 bytes)`, so a replayed, reordered or
/// reflected frame fails authentication.
class SecureChannel {
  SecureChannel(this._socket, List<int> key, {required bool isHost})
      : _key = SecretKey(key),
        _sendDir = isHost ? 1 : 2,
        _recvDir = isHost ? 2 : 1,
        _reader = _ByteReader(_socket);

  static const maxFrame = 1 << 20;
  static final _aes = AesGcm.with256bits();

  final Socket _socket;
  final SecretKey _key;
  final int _sendDir;
  final int _recvDir;
  final _ByteReader _reader;
  int _sendCounter = 0;
  int _recvCounter = 0;

  Future<void> send(int type, List<int> payload) async {
    final plain = Uint8List(payload.length + 1)
      ..[0] = type
      ..setRange(1, payload.length + 1, payload);
    final box = await _aes.encrypt(plain, secretKey: _key, nonce: _nonce(_sendDir, _sendCounter++));
    final len = box.cipherText.length + box.mac.bytes.length;
    final header = ByteData(4)..setUint32(0, len);
    _socket
      ..add(header.buffer.asUint8List())
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    await _socket.flush();
  }

  /// Next message; throws [SecretBoxAuthenticationError] on a bad frame.
  Future<Message> receive() async {
    final len = ByteData.sublistView(await _reader.read(4)).getUint32(0);
    if (len < 17 || len > maxFrame + 64) throw const FormatException('bad frame length');
    final frame = await _reader.read(len);
    final box = SecretBox(
      frame.sublist(0, len - 16),
      nonce: _nonce(_recvDir, _recvCounter++),
      mac: Mac(frame.sublist(len - 16)),
    );
    final plain = await _aes.decrypt(box, secretKey: _key);
    return Message(plain[0], Uint8List.fromList(plain).sublist(1));
  }

  Future<void> close() => _socket.close();

  static List<int> _nonce(int dir, int counter) {
    final b = ByteData(12)
      ..setUint32(0, dir)
      ..setUint64(4, counter);
    return b.buffer.asUint8List();
  }
}

class Message {
  Message(this.type, this.payload);

  final int type;
  final Uint8List payload;
}

/// Pulls exact byte counts out of a socket stream.
class _ByteReader {
  _ByteReader(Stream<Uint8List> source) : _it = StreamIterator(source);

  final StreamIterator<Uint8List> _it;
  final _chunks = <Uint8List>[];
  int _buffered = 0;

  Future<Uint8List> read(int n) async {
    while (_buffered < n) {
      if (!await _it.moveNext()) throw const SocketException('connection closed');
      _chunks.add(_it.current);
      _buffered += _it.current.length;
    }
    final out = Uint8List(n);
    var filled = 0;
    while (filled < n) {
      final head = _chunks.first;
      final take = (n - filled).clamp(0, head.length);
      out.setRange(filled, filled + take, head);
      filled += take;
      if (take == head.length) {
        _chunks.removeAt(0);
      } else {
        _chunks[0] = Uint8List.sublistView(head, take);
      }
    }
    _buffered -= n;
    return out;
  }
}
