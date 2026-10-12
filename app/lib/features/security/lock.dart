import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/secure_store.dart';
import 'pin_store.dart';

final secureStoreProvider = Provider<SecureStore>((ref) => const PlatformSecureStore());

final pinStoreProvider = Provider<PinStore>((ref) => PinStore(ref.watch(secureStoreProvider)));

/// Whether a PIN was set when the app started; overridden in `main`.
final initialPinEnabledProvider = Provider<bool>((ref) => false);

class LockState {
  const LockState({required this.pinEnabled, required this.locked});
  final bool pinEnabled, locked;
}

final lockProvider = NotifierProvider<LockController, LockState>(LockController.new);

class LockController extends Notifier<LockState> {
  DateTime? _backgroundSince;

  /// Set while the system biometric sheet is up: it sends the app to the
  /// inactive/hidden state, which must not count as leaving the app.
  bool authenticating = false;

  @override
  LockState build() {
    final enabled = ref.watch(initialPinEnabledProvider);
    return LockState(pinEnabled: enabled, locked: enabled);
  }

  void unlock() => state = LockState(pinEnabled: state.pinEnabled, locked: false);

  void pinChanged({required bool enabled}) => state = LockState(pinEnabled: enabled, locked: false);

  void wentToBackground(DateTime now) {
    if (authenticating) return;
    _backgroundSince ??= now;
  }

  void cameBack(DateTime now, Duration lockAfter) {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (authenticating || since == null || !state.pinEnabled) return;
    if (now.difference(since) >= lockAfter) {
      state = LockState(pinEnabled: true, locked: true);
    }
  }
}
