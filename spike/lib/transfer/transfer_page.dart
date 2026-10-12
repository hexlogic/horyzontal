import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../autotest.dart';
import 'protocol.dart';
import 'secure_channel.dart';
import 'wifi_link.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => TransferPageState();
}

class TransferPageState extends State<TransferPage> {
  bool _hostSends = true;
  bool _useHotspot = Platform.isAndroid;
  int _megabytes = 10;
  bool _busy = false;
  Invite? _invite;
  ServerSocket? _server;
  double? _progress;
  final _log = <String>[];

  Future<void> runHostWith({required bool hostSends, required int megabytes, required bool hotspot}) {
    setState(() {
      _hostSends = hostSends;
      _megabytes = megabytes;
      _useHotspot = hotspot;
    });
    return _runHost();
  }

  Future<void> runClientWith(String invite, {required int megabytes, bool joinOnce = false}) {
    setState(() => _megabytes = megabytes);
    return _runClient(invite, joinOnce: joinOnce);
  }

  void _say(String line) {
    final t = DateTime.now();
    final stamp = '${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}'
        '.${(t.millisecond ~/ 100)}';
    Autotest.log('transfer: $line');
    if (mounted) setState(() => _log.insert(0, '$stamp  $line'));
  }

  void _onProgress(int done, int total) {
    if (mounted) setState(() => _progress = total == 0 ? null : done / total);
  }

  Future<void> _androidPermissions({bool camera = false}) async {
    if (!Platform.isAndroid) return;
    final res = await WifiLink.requestPermissions(camera: camera);
    _say('дозволи: ${res.entries.map((e) => '${e.key.split('.').last}: ${e.value}').join(', ')}');
  }

  Future<void> _runHost() async {
    setState(() {
      _busy = true;
      _progress = null;
    });
    Hotspot? hotspot;
    var apAddresses = <String>[];
    try {
      await _androidPermissions();
      if (_useHotspot) {
        _say('запуск LocalOnlyHotspot…');
        final before = (await localAddresses()).toSet();
        hotspot = await WifiLink.startHotspot();
        _say('точка: ${hotspot.ssid}, безпека ${hotspot.security}');
        apAddresses = await _waitForNewAddresses(before);
        _say('адреса точки: ${apAddresses.isEmpty ? 'не знайдено, беру всі' : apAddresses.join(', ')}');
      }
      final tmp = await getTemporaryDirectory();
      final file = _hostSends ? await makeTestFile(tmp, _megabytes) : null;
      final server = _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final key = Invite.newKey();
      // With a hotspot only its own subnet goes into the QR: in the field there
      // is no other shared network, and a home Wi-Fi route would hide hotspot bugs.
      final addrs = apAddresses.isNotEmpty ? apAddresses : await localAddresses();
      _say('слухаю ${addrs.join(', ')} : ${server.port}');
      final invite = Invite(
            ssid: hotspot?.ssid ?? '',
            psk: hotspot?.psk ?? '',
            security: hotspot?.security ?? 0,
            addresses: addrs,
            port: server.port,
            key: key,
            hostSends: _hostSends,
          );
      // Spike only: lets the desktop test script pick the invite up from the log.
      await Autotest.log('invite ${invite.encode()}');
      setState(() => _invite = invite);

      await for (final socket in server) {
        _say('підключення від ${socket.remoteAddress.address}');
        final ch = SecureChannel(socket, key, isHost: true);
        try {
          await expectHello(ch);
        } catch (e) {
          _say('відхилено (немає ключа?): $e');
          socket.destroy();
          continue;
        }
        setState(() => _invite = null);
        final stats = _hostSends
            ? await sendFile(ch, file!, _onProgress)
            : await receiveFile(ch, tmp, _onProgress);
        _say(stats.toString());
        await ch.close();
        break;
      }
    } catch (e) {
      _say('помилка: $e');
    } finally {
      await _server?.close();
      _server = null;
      if (hotspot != null) {
        await WifiLink.stopHotspot();
        _say('точку доступу вимкнено');
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _invite = null;
        });
      }
    }
  }

  /// The soft AP interface gets its address a moment after onStarted.
  Future<List<String>> _waitForNewAddresses(Set<String> before) async {
    for (var i = 0; i < 25; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final fresh = (await localAddresses()).where((a) => !before.contains(a)).toList();
      if (fresh.isNotEmpty) return fresh;
    }
    return [];
  }

  Future<void> _cancelHost() async {
    await _server?.close();
  }

  Future<void> _runClient(String raw, {bool joinOnce = false}) async {
    setState(() {
      _busy = true;
      _progress = null;
    });
    String? joined;
    try {
      final inv = Invite.decode(raw);
      if (inv.ssid.isNotEmpty) {
        _say('підключаюсь до мережі ${inv.ssid}…');
        joined = inv.ssid;
        // iOS sometimes reports success and then never associates (seen 2 of 9
        // times on iPhone 16 Pro Max, iOS 27). Only detectable with joinOnce off.
        for (var attempt = 1; attempt <= 3; attempt++) {
          await WifiLink.join(inv.ssid, inv.psk, inv.security, joinOnce: joinOnce);
          _say('мережу прийнято системою (спроба $attempt, joinOnce: $joinOnce)');
          if (!Platform.isIOS || joinOnce || await _waitForSsid(inv.ssid)) break;
          _say('iOS не підключився, повторюю');
          await WifiLink.leave(inv.ssid);
        }
      }
      final socket = await connectAny(inv.addresses, inv.port, log: _say);
      _say('TCP з ${socket.remoteAddress.address}');
      final ch = SecureChannel(socket, inv.key, isHost: false);
      await sendHello(ch);
      final tmp = await getTemporaryDirectory();
      final stats = inv.hostSends
          ? await receiveFile(ch, tmp, _onProgress)
          : await sendFile(ch, await makeTestFile(tmp, _megabytes), _onProgress);
      _say(stats.toString());
      await ch.close();
    } catch (e) {
      _say('помилка: $e');
    } finally {
      if (joined != null) await WifiLink.leave(joined);
      if (mounted) setState(() => _busy = false);
    }
  }

  /// True once the phone is actually on [ssid]; iOS reports success before
  /// (or instead of) associating.
  Future<bool> _waitForSsid(String ssid, {Duration within = const Duration(seconds: 6)}) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < within) {
      if (await WifiLink.currentSsid() == ssid) {
        _say('у мережі $ssid через ${sw.elapsedMilliseconds} мс');
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  Future<void> _scan() async {
    await _androidPermissions(camera: true);
    if (!mounted) return;
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage()),
    );
    if (raw != null) await _runClient(raw);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) await _runClient(data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    final invite = _invite;
    return Scaffold(
      appBar: AppBar(title: const Text('Передача по Wi-Fi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Хост', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Надсилає')),
              ButtonSegment(value: false, label: Text('Приймає')),
            ],
            selected: {_hostSends},
            onSelectionChanged: _busy ? null : (s) => setState(() => _hostSends = s.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Створити точку доступу'),
            subtitle: Text(Platform.isAndroid
                ? 'LocalOnlyHotspot; вимкніть, якщо обидва в одній мережі'
                : 'iOS не вміє: лише спільна мережа'),
            value: _useHotspot,
            onChanged: _busy || !Platform.isAndroid ? null : (v) => setState(() => _useHotspot = v),
          ),
          Row(
            children: [
              const Text('Тестовий файл: '),
              DropdownButton<int>(
                value: _megabytes,
                items: const [1, 10, 50, 100]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m МБ')))
                    .toList(),
                onChanged: _busy ? null : (v) => setState(() => _megabytes = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (invite == null)
            FilledButton.icon(
              onPressed: _busy ? null : _runHost,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Запустити хост'),
            )
          else ...[
            Center(
              child: QrImageView(data: invite.encode(), size: 280, backgroundColor: Colors.white),
            ),
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: invite.encode())),
              icon: const Icon(Icons.copy),
              label: const Text('Копіювати запрошення'),
            ),
            OutlinedButton(onPressed: _cancelHost, child: const Text('Скасувати')),
          ],
          const Divider(height: 32),
          Text('Клієнт', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Сканувати QR'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _busy ? null : _paste,
                tooltip: 'Запрошення з буфера',
                icon: const Icon(Icons.content_paste),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_busy) LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          for (final line in _log)
            Text(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ),
    );
  }
}

class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR хоста')),
      body: MobileScanner(
        onDetect: (capture) {
          final raw = capture.barcodes.firstOrNull?.rawValue;
          if (_done || raw == null || !raw.startsWith('{')) return;
          _done = true;
          Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}
