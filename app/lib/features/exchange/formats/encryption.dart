import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'bundle.dart';

/// Password-protected export container, extension [encryptedExtension]:
///
/// | offset | size | field                                         |
/// |-------:|-----:|-----------------------------------------------|
/// | 0      | 4    | magic `HRZE`                                  |
/// | 4      | 1    | container version, 1                          |
/// | 5      | 1    | KDF id, 1 = PBKDF2-HMAC-SHA256                |
/// | 6      | 4    | KDF iterations, big-endian                    |
/// | 10     | 1    | salt length s (16)                            |
/// | 11     | s    | salt                                          |
/// | 11+s   | 1    | nonce length n (12)                           |
/// | 12+s   | n    | AES-GCM nonce                                 |
/// | 12+s+n | …    | AES-256-GCM ciphertext, then the 16-byte tag  |
///
/// Everything before the ciphertext is the GCM associated data, so a
/// tampered header fails like a wrong password. The plaintext is the export
/// file as is (.hrz, .kml, .zip…); the importer detects its format again.
const encryptedExtension = '.hrze';

/// Default PBKDF2 work factor (OWASP 2023 asks for 600 000 for SHA-256; this
/// is a compromise for pure-Dart phones, above the spec's 200 000).
const defaultKdfIterations = 250000;

/// Decryption refuses files asking for more than this, so a crafted header
/// cannot hang the app.
const maxKdfIterations = 10000000;

const _magic = [0x48, 0x52, 0x5A, 0x45]; // HRZE
const _version = 1;
const _kdfPbkdf2Sha256 = 1;
const _saltLength = 16;
const _nonceLength = 12;
const _tagLength = 16;

bool isEncryptedExport(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == _magic[0] &&
    bytes[1] == _magic[1] &&
    bytes[2] == _magic[2] &&
    bytes[3] == _magic[3];

final _random = Random.secure();

List<int> _randomBytes(int n) => List<int>.generate(n, (_) => _random.nextInt(256));

Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) => Pbkdf2(
  macAlgorithm: Hmac.sha256(),
  iterations: iterations,
  bits: 256,
).deriveKeyFromPassword(password: password, nonce: salt);

/// Encrypts an export with [password]. Slow on purpose (PBKDF2); run it
/// off the UI isolate for large files if needed.
Future<Uint8List> encryptExport(
  Uint8List data,
  String password, {
  int iterations = defaultKdfIterations,
}) async {
  if (iterations < 1 || iterations > maxKdfIterations) {
    throw ArgumentError.value(iterations, 'iterations');
  }
  final salt = _randomBytes(_saltLength);
  final nonce = _randomBytes(_nonceLength);
  final header = BytesBuilder(copy: false)
    ..add(_magic)
    ..addByte(_version)
    ..addByte(_kdfPbkdf2Sha256)
    ..add([
      (iterations >> 24) & 0xFF,
      (iterations >> 16) & 0xFF,
      (iterations >> 8) & 0xFF,
      iterations & 0xFF,
    ])
    ..addByte(_saltLength)
    ..add(salt)
    ..addByte(_nonceLength)
    ..add(nonce);
  final aad = header.toBytes();
  final key = await _deriveKey(password, salt, iterations);
  final box = await AesGcm.with256bits().encrypt(data, secretKey: key, nonce: nonce, aad: aad);
  return (BytesBuilder(copy: false)
        ..add(aad)
        ..add(box.cipherText)
        ..add(box.mac.bytes))
      .toBytes();
}

/// Decrypts a container made by [encryptExport]. Throws [WrongPassword]
/// when the password (or the file) is wrong and an [ImportException] with
/// [ImportException.encryptedCorrupt] when it is not a container we read.
Future<Uint8List> decryptExport(Uint8List data, String password) async {
  const corrupt = ImportException(ImportException.encryptedCorrupt);
  if (!isEncryptedExport(data) || data.length < 12) throw corrupt;
  if (data[4] != _version || data[5] != _kdfPbkdf2Sha256) {
    throw ImportException(ImportException.encryptedCorrupt, 'version ${data[4]}/${data[5]}');
  }
  final iterations = (data[6] << 24) | (data[7] << 16) | (data[8] << 8) | data[9];
  if (iterations < 1 || iterations > maxKdfIterations) throw corrupt;
  final saltLength = data[10];
  if (saltLength < 8 || data.length < 12 + saltLength) throw corrupt;
  final salt = data.sublist(11, 11 + saltLength);
  final nonceLength = data[11 + saltLength];
  final start = 12 + saltLength + nonceLength;
  if (nonceLength != _nonceLength || data.length < start + _tagLength) throw corrupt;
  final nonce = data.sublist(12 + saltLength, start);
  final aad = data.sublist(0, start);
  final cipherText = data.sublist(start, data.length - _tagLength);
  final mac = Mac(data.sublist(data.length - _tagLength));
  final key = await _deriveKey(password, salt, iterations);
  try {
    final clear = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: key,
      aad: aad,
    );
    return clear is Uint8List ? clear : Uint8List.fromList(clear);
  } on SecretBoxAuthenticationError {
    throw const WrongPassword();
  }
}
