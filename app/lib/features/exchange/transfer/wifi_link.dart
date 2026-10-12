import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'transport.dart';

/// Hotspot credentials from Android's LocalOnlyHotspot.
class Hotspot {
  Hotspot(this.ssid, this.psk, this.security);
  final String ssid, psk;

  /// SoftApConfiguration.SECURITY_TYPE_*: 0 open, 1 WPA2, 2 WPA3 transition, 3 WPA3.
  final int security;
}

/// Native side: MainActivity.kt (Android) and AppDelegate.swift (iOS).
abstract final class WifiLink {
  static const _ch = MethodChannel('horyzontal/wifi');

  /// Android only: iOS cannot create an access point.
  static Future<Hotspot> startHotspot() async {
    final r = await _ch.invokeMapMethod<String, Object?>('startHotspot');
    return Hotspot(r!['ssid']! as String, r['psk']! as String, r['security']! as int);
  }

  static Future<void> stopHotspot() => _ch.invokeMethod('stopHotspot');

  /// Android: NEARBY_WIFI_DEVICES (13+) or location (8-12), optionally camera.
  static Future<bool> requestPermissions({bool camera = false}) async {
    if (!Platform.isAndroid) return true;
    final r = await _ch.invokeMapMethod<String, bool>('requestPermissions', {'camera': camera});
    return r!.values.every((v) => v);
  }

  /// NEHotspotConfiguration on iOS, WifiNetworkSpecifier (10+) or
  /// WifiManager (8-9) on Android.
  static Future<void> join(String ssid, String psk, int security) =>
      _ch.invokeMethod('join', {'ssid': ssid, 'psk': psk, 'security': security, 'joinOnce': false});

  /// iOS only: the SSID the phone is actually on.
  static Future<String?> currentSsid() => _ch.invokeMethod<String>('currentSsid');

  static Future<void> leave(String ssid) => _ch.invokeMethod('leave', {'ssid': ssid});
}

enum InviteMode {
  /// Android hotspot: join its network, then TCP.
  hotspot,

  /// Both phones are already on one network: TCP only.
  lan,

  /// iPhone to iPhone over Multipeer Connectivity.
  multipeer,
}

/// What the host's QR carries: how to reach it and the session key.
class Invite {
  Invite({
    required this.mode,
    required this.key,
    required this.hostSends,
    this.ssid = '',
    this.psk = '',
    this.security = 0,
    this.addresses = const [],
    this.port = 0,
    this.token = '',
  });

  final InviteMode mode;
  final String ssid, psk, token;
  final int security, port;
  final List<String> addresses;
  final List<int> key;
  final bool hostSends;

  static List<int> newKey() {
    final rnd = Random.secure();
    return List.generate(32, (_) => rnd.nextInt(256));
  }

  static String newToken() {
    final rnd = Random.secure();
    return List.generate(10, (_) => 'abcdefghjkmnpqrstuvwxyz23456789'[rnd.nextInt(31)]).join();
  }

  String encode() => jsonEncode({
        'hrz': 2,
        'm': mode.name,
        if (ssid.isNotEmpty) 's': ssid,
        if (psk.isNotEmpty) 'p': psk,
        if (mode == InviteMode.hotspot) 't': security,
        if (addresses.isNotEmpty) 'a': addresses,
        if (port != 0) 'o': port,
        if (token.isNotEmpty) 'n': token,
        'k': base64Url.encode(key),
        'd': hostSends ? 's' : 'r',
      });

  static Invite? tryDecode(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      if (j['hrz'] != 2) return null;
      final key = base64Url.decode(j['k']! as String);
      if (key.length != 32) return null;
      return Invite(
        mode: InviteMode.values.byName(j['m']! as String),
        ssid: j['s'] as String? ?? '',
        psk: j['p'] as String? ?? '',
        security: j['t'] as int? ?? 0,
        addresses: [...(j['a'] as List<Object?>? ?? const []).cast<String>()],
        port: j['o'] as int? ?? 0,
        token: j['n'] as String? ?? '',
        key: key,
        hostSends: j['d'] == 's',
      );
    } catch (_) {
      return null;
    }
  }
}

/// IPv4 addresses of this device, hotspot-looking interfaces first.
Future<List<String>> localAddresses() async {
  final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  int rank(NetworkInterface i) {
    final n = i.name.toLowerCase();
    if (n.startsWith('ap') || n.contains('softap') || n.startsWith('swlan')) return 0;
    if (i.addresses.any((a) => a.address.startsWith('192.168.'))) return 1;
    if (n.startsWith('wlan') || n.startsWith('en')) return 2;
    return 3;
  }

  ifaces.sort((a, b) => rank(a).compareTo(rank(b)));
  return [
    for (final i in ifaces)
      for (final a in i.addresses)
        if (!a.isLoopback && !a.isLinkLocal) a.address,
  ].take(4).toList();
}

/// The soft AP interface gets its address a moment after the hotspot starts;
/// only its addresses go into the QR (a home Wi-Fi address would silently
/// route through the router, as seen in the spike).
Future<List<String>> waitForNewAddresses(Set<String> before) async {
  for (var i = 0; i < 25; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final fresh = (await localAddresses()).where((a) => !before.contains(a)).toList();
    if (fresh.isNotEmpty) return fresh;
  }
  return [];
}

/// Tries every address until one accepts. The first attempts often fail while
/// the phone is still associating or iOS shows the local network prompt.
Future<Socket> connectAny(List<String> addresses, int port,
    {Duration deadline = const Duration(seconds: 40)}) async {
  final end = DateTime.now().add(deadline);
  Object? last;
  while (DateTime.now().isBefore(end)) {
    try {
      return await _firstSuccess([
        for (final a in addresses) Socket.connect(a, port, timeout: const Duration(milliseconds: 1500)),
      ]);
    } catch (e) {
      last = e;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }
  throw SocketException('connect failed: $last');
}

Future<Socket> _firstSuccess(List<Future<Socket>> attempts) {
  final done = Completer<Socket>();
  var failed = 0;
  for (final f in attempts) {
    f.then((s) => done.isCompleted ? s.destroy() : done.complete(s), onError: (Object e) {
      if (++failed == attempts.length && !done.isCompleted) done.completeError(e);
    });
  }
  return done.future;
}

/// iPhone to iPhone: Multipeer Connectivity (Wi-Fi peer-to-peer or
/// Bluetooth, no access point). The host advertises [Invite.token]; the
/// client looks for that token and connects. MCSession is created with
/// required encryption, and our own AES-GCM frames run on top anyway.
class MultipeerTransport implements Transport {
  MultipeerTransport._(this._input, this._sub);

  static const _ch = MethodChannel('horyzontal/mpc');
  static const _ev = EventChannel('horyzontal/mpc/events');

  final StreamController<Uint8List> _input;
  final StreamSubscription<Object?> _sub;
  final _buffer = BytesBuilder(copy: false);

  /// Advertises [token] and completes when a peer has connected.
  static Future<MultipeerTransport> host(String token) => _start('host', token);

  /// Browses for [token] and completes when connected to that host.
  static Future<MultipeerTransport> join(String token) => _start('join', token);

  static Future<MultipeerTransport> _start(String method, String token) async {
    // Data is buffered from the first event: the peer may send its HELLO
    // before anyone on this side reads.
    final input = StreamController<Uint8List>();
    final connected = Completer<void>();
    final sub = _ev.receiveBroadcastStream().listen((e) {
      final m = e as Map<Object?, Object?>;
      switch (m['type']) {
        case 'connected':
          if (!connected.isCompleted) connected.complete();
        case 'data':
          input.add(m['bytes']! as Uint8List);
        case 'disconnected':
          if (connected.isCompleted) input.close();
        case 'error':
          if (!connected.isCompleted) connected.completeError(StateError('${m['message']}'));
      }
    });
    try {
      await _ch.invokeMethod(method, {'token': token});
      await connected.future.timeout(const Duration(minutes: 3));
    } catch (_) {
      await sub.cancel();
      await _ch.invokeMethod('stop');
      rethrow;
    }
    return MultipeerTransport._(input, sub);
  }

  @override
  Stream<Uint8List> get input => _input.stream;

  @override
  void add(List<int> bytes) => _buffer.add(bytes);

  @override
  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    await _ch.invokeMethod('send', _buffer.takeBytes());
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    await _input.close();
    await _ch.invokeMethod('stop');
  }
}
