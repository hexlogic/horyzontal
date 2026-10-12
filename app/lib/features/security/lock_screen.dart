import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import 'lock.dart';
import 'pin_pad.dart';
import 'pin_store.dart';

/// Covers the app while locked. Offers biometrics first when enabled.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pad = GlobalKey<PinPadState>();
  String? _message;
  bool _error = false;
  DateTime? _blockedUntil;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _checkBlock();
    if (ref.read(settingsProvider).biometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _checkBlock() async {
    final until = await ref.read(pinStoreProvider).blockedUntil();
    if (until != null) _block(until);
  }

  void _block(DateTime until) {
    _blockedUntil = until;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (DateTime.now().isAfter(until)) {
        _ticker?.cancel();
        setState(() {
          _blockedUntil = null;
          _message = null;
        });
      } else {
        setState(() {});
      }
    });
    setState(() {});
  }

  Future<void> _biometric() async {
    final lock = ref.read(lockProvider.notifier);
    final reason = context.l10n.biometricReason;
    lock.authenticating = true;
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      if (ok) lock.unlock();
    } on LocalAuthException {
      // Not enrolled, cancelled or locked out: the PIN remains.
    } finally {
      lock.authenticating = false;
    }
  }

  Future<void> _submit(String pin) async {
    final l = context.l10n;
    final r = await ref.read(pinStoreProvider).verify(pin);
    if (!mounted) return;
    _pad.currentState?.clear();
    switch (r) {
      case PinOk():
        ref.read(lockProvider.notifier).unlock();
      case PinWrong():
        setState(() {
          _message = l.pinWrong;
          _error = true;
        });
      case PinBlocked(:final until):
        _block(until);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final blocked = _blockedUntil;
    final wait = blocked == null ? 0 : blocked.difference(DateTime.now()).inSeconds + 1;
    final biometrics = ref.watch(settingsProvider).biometrics;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: PinPad(
              key: _pad,
              title: l.pinEnter,
              enabled: blocked == null,
              message: blocked != null ? l.pinWait(wait) : _message,
              messageIsError: blocked != null || _error,
              onComplete: _submit,
              onBiometric: biometrics ? _biometric : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts [LockScreen] over [child] while locked and locks after the app has
/// been in the background for the configured time.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(lockProvider.notifier).wentToBackground(DateTime.now()),
      onShow: () => ref
          .read(lockProvider.notifier)
          .cameBack(DateTime.now(), ref.read(settingsProvider).lockAfter),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(lockProvider.select((s) => s.locked));
    return Stack(
      children: [
        // Kept in the tree so that screens keep their state behind the lock.
        ExcludeSemantics(
          excluding: locked,
          child: IgnorePointer(ignoring: locked, child: widget.child),
        ),
        if (locked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
