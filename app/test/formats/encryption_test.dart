import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/exchange/formats/formats.dart';

import 'samples.dart';

void main() {
  final plain = exportLayers(sampleLayers(), ExportFormat.hrz, now: now);

  test('round trip with the default work factor', () async {
    final watch = Stopwatch()..start();
    final sealed = await encryptExport(plain, 'пароль-1');
    final encryptMs = watch.elapsedMilliseconds;
    expect(isEncryptedExport(sealed), isTrue);
    expect(ascii.decode(sealed.sublist(0, 4)), 'HRZE');
    expect(sealed[4], 1, reason: 'container version');
    expect(sealed[5], 1, reason: 'PBKDF2-HMAC-SHA256');
    final iterations = (sealed[6] << 24) | (sealed[7] << 16) | (sealed[8] << 8) | sealed[9];
    expect(iterations, defaultKdfIterations);
    expect(iterations, greaterThanOrEqualTo(200000));
    expect(sealed.length, plain.length + 4 + 1 + 1 + 4 + 1 + 16 + 1 + 12 + 16);
    expect(await decryptExport(sealed, 'пароль-1'), plain);
    // Recorded for the report: pure Dart cost on the build machine.
    printOnFailure('encrypt ${encryptMs}ms');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('salt and nonce are fresh each time', () async {
    final a = await encryptExport(plain, 'p', iterations: 1000);
    final b = await encryptExport(plain, 'p', iterations: 1000);
    expect(a, isNot(b));
  });

  test('wrong password, tampering, truncation', () async {
    final sealed = await encryptExport(plain, 'right', iterations: 1000);
    await expectLater(decryptExport(sealed, 'wrong'), throwsA(isA<WrongPassword>()));

    final flipped = Uint8List.fromList(sealed)..[sealed.length - 40] ^= 1;
    await expectLater(decryptExport(flipped, 'right'), throwsA(isA<WrongPassword>()));

    // A changed iteration count is authenticated data: fails like a wrong password.
    final header = Uint8List.fromList(sealed)..[9] ^= 1;
    await expectLater(decryptExport(header, 'right'), throwsA(isA<WrongPassword>()));

    final huge = Uint8List.fromList(sealed)..[6] = 0x7F;
    await expectLater(
      decryptExport(huge, 'right'),
      throwsA(
        isA<ImportException>().having((e) => e.code, 'code', ImportException.encryptedCorrupt),
      ),
    );
    final future = Uint8List.fromList(sealed)..[4] = 2;
    await expectLater(
      decryptExport(future, 'right'),
      throwsA(
        isA<ImportException>().having((e) => e.code, 'code', ImportException.encryptedCorrupt),
      ),
    );
    await expectLater(
      decryptExport(sealed.sublist(0, 30), 'right'),
      throwsA(
        isA<ImportException>().having((e) => e.code, 'code', ImportException.encryptedCorrupt),
      ),
    );
  });

  test('importFile asks for the password, then decrypts', () async {
    for (final format in ExportFormat.values) {
      final bytes = exportLayers(sampleLayers(), format, now: now);
      final sealed = await encryptExport(bytes, 'секрет', iterations: 1000);
      final name = '${suggestedFileName(sampleLayers(), format)}$encryptedExtension';
      await expectLater(importFile(name, sealed), throwsA(isA<PasswordRequired>()));
      await expectLater(importFile(name, sealed, password: 'ні'), throwsA(isA<WrongPassword>()));
      final r = await importFile(name, sealed, password: 'секрет', now: now);
      expect(r.layers, isNotEmpty, reason: format.name);
      expect(r.layers.first.layer.name, 'Опорний пункт «Сокіл»');
    }
    // Synchronous import refuses encrypted files with the same exception.
    final sealed = await encryptExport(plain, 'x', iterations: 1000);
    expect(() => importPlainFile('a.hrze', sealed), throwsA(isA<PasswordRequired>()));
  });

  test('PBKDF2 matches the RFC 7914 vector', () async {
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 1,
      bits: 512,
    ).deriveKeyFromPassword(password: 'passwd', nonce: utf8.encode('salt'));
    final hex = (await key.extractBytes()).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(hex, startsWith('55ac046e56e3089fec1691c22544b605'));
  });
}
