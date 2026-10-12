import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/data/model.dart';
import '../../../core/data/repository.dart';
import '../../../core/labels.dart';
import '../../settings/about_page.dart';
import '../formats/formats.dart';
import '../import_flow.dart';
import 'protocol.dart';
import 'secure_channel.dart';
import 'transport.dart';
import 'wifi_link.dart';

enum _Stage { choose, hosting, scanning, connecting, transferring, done, failed }

/// Layer transfer without internet. The phone that shows the QR is the
/// host: an Android phone raises a local hotspot (iPhones cannot), an iPhone
/// talking to another iPhone uses Multipeer Connectivity. Which side sends
/// does not depend on who hosts.
class TransferPage extends ConsumerStatefulWidget {
  const TransferPage({super.key, this.layerIds = const []});

  /// Layers to send; empty means this phone receives.
  final List<String> layerIds;

  @override
  ConsumerState<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends ConsumerState<TransferPage> {
  _Stage _stage = _Stage.choose;
  Invite? _invite;
  String? _error;
  String _status = '';
  double? _progress;
  ServerSocket? _server;
  Hotspot? _hotspot;
  String? _joinedSsid;
  SecureChannel? _channel;
  bool _sameNetwork = false;
  bool _cancelled = false;
  List<MapLayer> _layers = const [];

  bool get _sending => widget.layerIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_sending) {
      ref.read(repositoryProvider).layers().then((all) {
        if (mounted) setState(() => _layers = all.where((l) => widget.layerIds.contains(l.id)).toList());
      });
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    await _channel?.close().catchError((_) {});
    _channel = null;
    await _server?.close();
    _server = null;
    if (_hotspot != null) {
      _hotspot = null;
      await WifiLink.stopHotspot().catchError((_) {});
    }
    if (_joinedSsid != null) {
      final ssid = _joinedSsid!;
      _joinedSsid = null;
      await WifiLink.leave(ssid).catchError((_) {});
    }
  }

  void _fail(Object e) {
    if (!mounted || _cancelled) return;
    setState(() {
      _stage = _Stage.failed;
      _error = '$e';
    });
    _cleanup();
  }

  Future<Uint8List> _payload() async {
    final repo = ref.read(repositoryProvider);
    final bundles = [for (final l in _layers) LayerBundle(l, await repo.featuresOf(l.id))];
    return exportLayers(bundles, ExportFormat.hrz, appVersion: appVersion);
  }

  // --- Host -----------------------------------------------------------------

  Future<void> _host() async {
    final l = context.l10n;
    setState(() {
      _stage = _Stage.hosting;
      _status = l.transferStarting;
    });
    try {
      final key = Invite.newKey();
      Invite invite;
      Future<SecureChannel> accept;
      if (Platform.isIOS && !_sameNetwork) {
        final token = Invite.newToken();
        invite = Invite(mode: InviteMode.multipeer, token: token, key: key, hostSends: _sending);
        accept = MultipeerTransport.host(token).then((t) async {
          final ch = SecureChannel(t, key, isHost: true);
          await expectHello(ch);
          return ch;
        });
      } else {
        var addresses = <String>[];
        if (Platform.isAndroid && !_sameNetwork) {
          if (!await WifiLink.requestPermissions()) throw StateError(l.transferPermission);
          final before = (await localAddresses()).toSet();
          _hotspot = await WifiLink.startHotspot();
          addresses = await waitForNewAddresses(before);
        }
        if (addresses.isEmpty) addresses = await localAddresses();
        final server = _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
        final h = _hotspot;
        invite = Invite(
          mode: h == null ? InviteMode.lan : InviteMode.hotspot,
          ssid: h?.ssid ?? '',
          psk: h?.psk ?? '',
          security: h?.security ?? 0,
          addresses: addresses,
          port: server.port,
          key: key,
          hostSends: _sending,
        );
        // Anyone on the hotspot may connect; only a client that proves it
        // has the key from the QR gets a session, the rest are dropped.
        accept = () async {
          await for (final socket in server) {
            final ch = SecureChannel(SocketTransport(socket), key, isHost: true);
            try {
              await expectHello(ch);
              return ch;
            } catch (_) {
              socket.destroy();
            }
          }
          throw StateError('server closed');
        }();
      }
      if (!mounted) return;
      setState(() {
        _invite = invite;
        _status = l.transferShowQr;
      });
      final ch = _channel = await accept;
      await _run(ch);
    } catch (e) {
      _fail(e);
    }
  }

  // --- Client ---------------------------------------------------------------

  Future<void> _scan() async {
    if (Platform.isAndroid) await WifiLink.requestPermissions(camera: true);
    setState(() => _stage = _Stage.scanning);
  }

  Future<void> _onScanned(String raw) async {
    final l = context.l10n;
    final inv = Invite.tryDecode(raw);
    if (inv == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.transferBadQr)));
      return;
    }
    if (inv.hostSends == _sending) {
      _fail(_sending ? l.transferBothSend : l.transferBothReceive);
      return;
    }
    setState(() {
      _stage = _Stage.connecting;
      _status = l.transferConnecting;
    });
    try {
      Transport transport;
      switch (inv.mode) {
        case InviteMode.multipeer:
          if (!Platform.isIOS) throw StateError(l.transferNeedsIphone);
          transport = await MultipeerTransport.join(inv.token);
        case InviteMode.hotspot:
          if (Platform.isAndroid && !await WifiLink.requestPermissions()) {
            throw StateError(l.transferPermission);
          }
          _joinedSsid = inv.ssid;
          // iOS may accept the network and never join (stage 0: 2 of 12):
          // check the SSID and retry.
          for (var attempt = 1; attempt <= 3; attempt++) {
            await WifiLink.join(inv.ssid, inv.psk, inv.security);
            if (!Platform.isIOS || await _waitForSsid(inv.ssid)) break;
            await WifiLink.leave(inv.ssid);
            if (attempt == 3) throw StateError(l.transferJoinFailed(inv.ssid, inv.psk));
          }
          transport = SocketTransport(await connectAny(inv.addresses, inv.port));
        case InviteMode.lan:
          transport = SocketTransport(await connectAny(inv.addresses, inv.port));
      }
      final ch = _channel = SecureChannel(transport, inv.key, isHost: false);
      await sendHello(ch);
      await _run(ch);
    } catch (e) {
      _fail(e);
    }
  }

  Future<bool> _waitForSsid(String ssid) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < const Duration(seconds: 6)) {
      if (await WifiLink.currentSsid() == ssid) return true;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  // --- Both -----------------------------------------------------------------

  Future<void> _run(SecureChannel ch) async {
    final l = context.l10n;
    setState(() {
      _stage = _Stage.transferring;
      _invite = null;
      _status = _sending ? l.transferSending : l.transferReceiving;
    });
    void progress(int done, int total) {
      if (mounted) setState(() => _progress = total == 0 ? null : done / total);
    }

    if (_sending) {
      final payload = await _payload();
      final summary = [
        for (final layer in _layers)
          LayerSummary(layer.name, (await ref.read(repositoryProvider).featuresOf(layer.id)).length),
      ];
      final ok = await sendLayers(ch, summary, payload, onProgress: progress);
      await _cleanup();
      if (!mounted) return;
      setState(() {
        _stage = ok ? _Stage.done : _Stage.failed;
        _status = ok ? l.transferSent : '';
        _error = ok ? null : l.transferChecksum;
      });
      return;
    }

    final got = await receiveLayers(ch, onProgress: progress);
    await _cleanup();
    if (!mounted) return;
    if (got == null) {
      _fail(l.transferChecksum);
      return;
    }
    final result = await importFile('transfer.hrz', got.$2);
    if (!mounted) return;
    final ok = await confirmImport(context, result.layers);
    if (ok == true) {
      final n = await saveImported(ref.read(repositoryProvider), result.layers);
      if (!mounted) return;
      setState(() {
        _stage = _Stage.done;
        _status = l.imported(n);
      });
    } else {
      setState(() {
        _stage = _Stage.done;
        _status = l.transferDeclined;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final invite = _invite;
    return Scaffold(
      appBar: AppBar(title: Text(_sending ? l.sendWifi : l.receiveWifi)),
      body: switch (_stage) {
        _Stage.choose => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_sending)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.layers_outlined),
                    title: Text(_layers.map((x) => x.name).join(', ')),
                    subtitle: Text(l.transferLayersToSend),
                  ),
                ),
              Text(l.transferHowTo, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: Text(l.transferShowQrButton),
                onPressed: _host,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l.transferScanButton),
                onPressed: _scan,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.transferSameNetwork),
                subtitle: Text(l.transferSameNetworkHint),
                value: _sameNetwork,
                onChanged: (v) => setState(() => _sameNetwork = v),
              ),
            ],
          ),
        _Stage.scanning => MobileScanner(
            onDetect: (c) {
              final raw = c.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
              if (raw != null && _stage == _Stage.scanning) _onScanned(raw);
            },
          ),
        _Stage.hosting when invite != null => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: QrImageView(
                  data: invite.encode(),
                  size: 300,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 12),
              Text(_status, textAlign: TextAlign.center),
              if (invite.mode == InviteMode.hotspot) ...[
                const SizedBox(height: 12),
                // Manual fallback if the other phone cannot join by itself.
                Text(l.transferManual(invite.ssid, invite.psk),
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              OutlinedButton(onPressed: () => context.pop(), child: Text(l.cancel)),
            ],
          ),
        _Stage.done || _Stage.failed => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_stage == _Stage.done ? Icons.check_circle_outline : Icons.error_outline, size: 64),
                  const SizedBox(height: 12),
                  Text(_stage == _Stage.done ? _status : l.transferFailed(_error ?? ''),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => context.pop(), child: Text(l.close)),
                ],
              ),
            ),
          ),
        _ => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: _progress),
                  const SizedBox(height: 16),
                  Text(_status, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
      },
    );
  }
}
