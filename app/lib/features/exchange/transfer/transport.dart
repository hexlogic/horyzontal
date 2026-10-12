import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// A reliable ordered byte pipe: a TCP socket, or a Multipeer Connectivity
/// session between two iPhones.
abstract class Transport {
  Stream<Uint8List> get input;
  void add(List<int> bytes);
  Future<void> flush();
  Future<void> close();
}

class SocketTransport implements Transport {
  SocketTransport(this.socket);
  final Socket socket;

  @override
  Stream<Uint8List> get input => socket;

  @override
  void add(List<int> bytes) => socket.add(bytes);

  @override
  Future<void> flush() => socket.flush();

  @override
  Future<void> close() async {
    await socket.close();
    socket.destroy();
  }
}
