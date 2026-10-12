import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

/// Hotspot credentials from Android's LocalOnlyHotspot.
class Hotspot {
  Hotspot(this.ssid, this.psk, this.security);

  final String ssid;
  final String psk;

  /// SoftApConfiguration.SECURITY_TYPE_*: 0 open, 1 WPA2, 2 WPA3 transition, 3 WPA3.
  final int security;
}

/// Native side: MainActivity.kt (Android) and WifiLinkPlugin.swift (iOS).
abstract final class WifiLink {
  static const _ch = MethodChannel('horyzontal/wifi');

  /// Android only: iOS cannot create an access point.
  static Future<Hotspot> startHotspot() async {
    final r = await _ch.invokeMapMethod<String, dynamic>('startHotspot');
    return Hotspot(r!['ssid'] as String, r['psk'] as String, r['security'] as int);
  }

  /// Android only; returns permission -> granted.
  static Future<Map<String, bool>> requestPermissions({bool camera = false}) async =>
      (await _ch.invokeMapMethod<String, bool>('requestPermissions', {'camera': camera}))!;

  static Future<void> stopHotspot() => _ch.invokeMethod('stopHotspot');

  /// Joins the host's network: NEHotspotConfiguration on iOS,
  /// WifiNetworkSpecifier (Android 10+) or WifiManager (8-9) on Android.
  static Future<void> join(String ssid, String psk, int security, {bool joinOnce = true}) =>
      _ch.invokeMethod('join', {'ssid': ssid, 'psk': psk, 'security': security, 'joinOnce': joinOnce});

  /// iOS only: SSID the phone is actually on right now.
  static Future<String?> currentSsid() => _ch.invokeMethod<String>('currentSsid');

  static Future<void> leave(String ssid) => _ch.invokeMethod('leave', {'ssid': ssid});
}

/// What the host's QR carries. Everything needed to join and decrypt.
class Invite {
  Invite({
    required this.ssid,
    required this.psk,
    required this.security,
    required this.addresses,
    required this.port,
    required this.key,
    required this.hostSends,
  });

  final String ssid;
  final String psk;
  final int security;
  final List<String> addresses;
  final int port;
  final List<int> key;
  final bool hostSends;

  static List<int> newKey() {
    final rnd = Random.secure();
    return List.generate(32, (_) => rnd.nextInt(256));
  }

  String encode() => jsonEncode({
        'v': 1,
        's': ssid,
        'p': psk,
        't': security,
        'a': addresses,
        'o': port,
        'k': base64Url.encode(key),
        'm': hostSends ? 's' : 'r',
      });

  static Invite decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['v'] != 1) throw const FormatException('unknown invite version');
    return Invite(
      ssid: j['s'] as String,
      psk: j['p'] as String,
      security: j['t'] as int,
      addresses: (j['a'] as List).cast<String>(),
      port: j['o'] as int,
      key: base64Url.decode(j['k'] as String),
      hostSends: j['m'] == 's',
    );
  }
}

/// IPv4 addresses of this device, hotspot-looking interfaces first.
/// Dart doesn't know which interface is the soft AP, so the QR carries all
/// of them and the client races connections.
Future<List<String>> localAddresses() async {
  final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  int rank(NetworkInterface i) {
    final n = i.name.toLowerCase();
    if (n.startsWith('ap') || n.contains('softap') || n.startsWith('swlan')) return 0;
    if (i.addresses.any((a) => a.address.startsWith('192.168.'))) return 1;
    if (n.startsWith('wlan')) return 2;
    return 3;
  }

  ifaces.sort((a, b) => rank(a).compareTo(rank(b)));
  return [
    for (final i in ifaces)
      for (final a in i.addresses)
        if (!a.isLoopback) a.address,
  ].take(4).toList();
}

/// Tries every address until one accepts, for up to [deadline]. The first
/// attempts often fail while the phone is still associating or while iOS
/// shows the local network permission prompt.
Future<Socket> connectAny(
  List<String> addresses,
  int port, {
  Duration deadline = const Duration(seconds: 40),
  void Function(String)? log,
}) async {
  final end = DateTime.now().add(deadline);
  var attempt = 0;
  while (DateTime.now().isBefore(end)) {
    attempt++;
    try {
      return await _firstSuccess([
        // Short timeout: right after association DHCP is still running and the
        // first SYN is lost; retrying fast beats waiting it out.
        for (final a in addresses) Socket.connect(a, port, timeout: const Duration(milliseconds: 1500)),
      ]);
    } catch (e) {
      log?.call('спроба $attempt: $e');
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }
  throw SocketException('не вдалося підключитися до ${addresses.join(', ')}:$port');
}

/// Like Future.any, but an error only wins when every attempt fails.
/// Late winners are closed so no socket leaks.
Future<Socket> _firstSuccess(List<Future<Socket>> attempts) {
  final done = Completer<Socket>();
  var failed = 0;
  for (final f in attempts) {
    f.then((s) {
      done.isCompleted ? s.destroy() : done.complete(s);
    }, onError: (Object e) {
      if (++failed == attempts.length && !done.isCompleted) done.completeError(e);
    });
  }
  return done.future;
}
