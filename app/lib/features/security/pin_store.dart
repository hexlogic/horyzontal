import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../core/secure_store.dart';

sealed class PinCheck {
  const PinCheck();
}

class PinOk extends PinCheck {
  const PinOk();
}

class PinWrong extends PinCheck {
  const PinWrong();
}

/// Too many failures: no attempts until [until].
class PinBlocked extends PinCheck {
  const PinBlocked(this.until);
  final DateTime until;
}

/// Six-digit PIN, stored as a salted PBKDF2-HMAC-SHA256 hash in the secure
/// store. After [freeAttempts] failures every further attempt waits, doubling
/// from 30 s up to an hour; the counter survives restarts.
class PinStore {
  PinStore(this._store, {this.iterations = 60000, DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final SecureStore _store;
  final int iterations;
  final DateTime Function() _now;

  static const length = 6;
  static const freeAttempts = 5;
  static const _hashKey = 'pin_hash_v1', _failKey = 'pin_failures', _untilKey = 'pin_blocked_until';

  Future<bool> hasPin() async => await _store.read(_hashKey) != null;

  Future<void> setPin(String pin) async {
    _checkFormat(pin);
    final rnd = Random.secure();
    final salt = List.generate(16, (_) => rnd.nextInt(256));
    final hash = await _derive(pin, salt, iterations);
    await _store.write(_hashKey, '$iterations:${base64.encode(salt)}:${base64.encode(hash)}');
    await _resetFailures();
  }

  Future<void> clear() async {
    await _store.delete(_hashKey);
    await _resetFailures();
  }

  /// Current block, if any, without spending an attempt.
  Future<DateTime?> blockedUntil() async {
    final until = int.tryParse(await _store.read(_untilKey) ?? '');
    if (until == null) return null;
    final t = DateTime.fromMillisecondsSinceEpoch(until);
    return t.isAfter(_now()) ? t : null;
  }

  Future<PinCheck> verify(String pin) async {
    final blocked = await blockedUntil();
    if (blocked != null) return PinBlocked(blocked);
    final stored = await _store.read(_hashKey);
    if (stored == null) return const PinOk();
    final parts = stored.split(':');
    final hash = await _derive(pin, base64.decode(parts[1]), int.parse(parts[0]));
    if (_constantTimeEquals(hash, base64.decode(parts[2]))) {
      await _resetFailures();
      return const PinOk();
    }
    final failures = (int.tryParse(await _store.read(_failKey) ?? '') ?? 0) + 1;
    await _store.write(_failKey, '$failures');
    if (failures >= freeAttempts) {
      final wait = Duration(seconds: min(3600, 30 * pow(2, failures - freeAttempts).toInt()));
      final until = _now().add(wait);
      await _store.write(_untilKey, '${until.millisecondsSinceEpoch}');
      return PinBlocked(until);
    }
    return const PinWrong();
  }

  Future<void> _resetFailures() async {
    await _store.delete(_failKey);
    await _store.delete(_untilKey);
  }

  static void _checkFormat(String pin) {
    if (!RegExp('^\\d{$length}\$').hasMatch(pin)) {
      throw ArgumentError('PIN must be $length digits');
    }
  }

  static Future<List<int>> _derive(String pin, List<int> salt, int iterations) async {
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final key = await kdf.deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a[i] ^ b[i];
    }
    return r == 0;
  }
}
