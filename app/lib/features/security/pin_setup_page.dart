import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';
import 'lock.dart';
import 'pin_pad.dart';
import 'pin_store.dart';

enum PinSetupMode { enable, change, disable }

/// Set, change or remove the PIN. Changing and removing ask for the current
/// PIN first.
class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key, required this.mode});
  final PinSetupMode mode;

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

enum _Step { current, fresh, repeat }

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final _pad = GlobalKey<PinPadState>();
  late _Step _step = widget.mode == PinSetupMode.enable ? _Step.fresh : _Step.current;
  String? _first, _message;
  bool _error = false;

  Future<void> _complete(String pin) async {
    final l = context.l10n;
    final store = ref.read(pinStoreProvider);
    _pad.currentState?.clear();
    switch (_step) {
      case _Step.current:
        final r = await store.verify(pin);
        if (!mounted) return;
        if (r is! PinOk) {
          setState(() {
            _error = true;
            _message = r is PinBlocked
                ? l.pinWait(r.until.difference(DateTime.now()).inSeconds + 1)
                : l.pinWrong;
          });
          return;
        }
        if (widget.mode == PinSetupMode.disable) {
          await store.clear();
          ref.read(lockProvider.notifier).pinChanged(enabled: false);
          _done(l.pinRemoved);
          return;
        }
        setState(() {
          _step = _Step.fresh;
          _message = null;
          _error = false;
        });
      case _Step.fresh:
        setState(() {
          _first = pin;
          _step = _Step.repeat;
          _message = null;
          _error = false;
        });
      case _Step.repeat:
        if (pin != _first) {
          setState(() {
            _step = _Step.fresh;
            _first = null;
            _message = l.pinMismatch;
            _error = true;
          });
          return;
        }
        await store.setPin(pin);
        ref.read(lockProvider.notifier).pinChanged(enabled: true);
        _done(l.pinSet);
    }
  }

  void _done(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = switch (_step) {
      _Step.current => l.pinCurrent,
      _Step.fresh => l.pinNew,
      _Step.repeat => l.pinRepeat,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.pinCode)),
      body: Center(
        child: SingleChildScrollView(
          child: PinPad(
            key: _pad,
            title: title,
            message: _message,
            messageIsError: _error,
            onComplete: _complete,
          ),
        ),
      ),
    );
  }
}
