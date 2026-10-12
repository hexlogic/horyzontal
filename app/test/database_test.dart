import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/db/database.dart';

const _key = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
const _other = 'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';

void main() {
  test('settings round trip through the encrypted database', () async {
    final db = AppDatabase.memory(_key);
    await db.writeSetting('callsign', 'Сокіл');
    await db.writeSetting('theme', 'dark');
    await db.writeSetting('theme', 'light');
    expect(await db.readSettings(), {'callsign': 'Сокіл', 'theme': 'light'});
    await db.writeSetting('callsign', null);
    expect(await db.readSettings(), {'theme': 'light'});
    await db.close();
  });

  test('file is encrypted and needs the key', () async {
    final dir = await Directory.systemTemp.createTemp('hrz');
    final file = File('${dir.path}/app.db');
    final db = AppDatabase.open(file, _key);
    await db.writeSetting('callsign', 'ПОЗИВНИЙ-ТЕСТ');
    await db.close();

    final bytes = await file.readAsBytes();
    expect(String.fromCharCodes(bytes.take(16)), isNot(startsWith('SQLite format 3')));
    expect(String.fromCharCodes(bytes).contains('callsign'), isFalse);

    final wrong = AppDatabase.open(file, _other);
    await expectLater(wrong.readSettings(), throwsA(anything));
    await wrong.close();

    final again = AppDatabase.open(file, _key);
    expect((await again.readSettings())['callsign'], 'ПОЗИВНИЙ-ТЕСТ');
    await again.close();
    await dir.delete(recursive: true);
  });
}
