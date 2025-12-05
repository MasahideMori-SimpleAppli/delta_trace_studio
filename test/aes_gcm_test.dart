import 'dart:typed_data';
import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/infrastructure/encryption/aes_gcm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AesGcm AES-GCM Encrypt/Decrypt Tests', () {
    const keyHex =
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    // 32 bytes → AES-256

    final aes = AesGcm();

    test('Encrypt → Decrypt returns original JSON', () {
      final dtdb = DeltaTraceDatabase();
      dtdb.executeQuery(
        RawQueryBuilder.add(
          target: "test",
          rawAddData: [
            {
              "name": "テスト",
              "value": 123,
              "flag": true,
              "nested": {
                "message": "こんにちは",
                "list": [1, 2, 3],
              },
            },
          ],
        ).build(),
      );
      final original = dtdb.toDict();

      // --- Encrypt ---
      final encrypted = aes.encryptJson(original, keyHex);
      expect(encrypted.length > 12, true); // nonce + ciphertext + tag

      // --- Decrypt ---
      final decrypted = aes.decryptJson(encrypted, keyHex);

      expect(decrypted, equals(original));
    });

    test(
      'Different encryptions produce different ciphertext (due to random nonce)',
      () {
        final data = {"message": "hello"};

        final enc1 = aes.encryptJson(data, keyHex);
        final enc2 = aes.encryptJson(data, keyHex);

        // nonce が毎回ランダム → ciphertext も必ず違う
        expect(enc1, isNot(equals(enc2)));
      },
    );

    test('Invalid data length throws exception', () {
      final tooShort = Uint8List.fromList([1, 2, 3, 4]);

      expect(
        () => aes.decryptJson(tooShort, keyHex),
        throwsA(isA<Exception>()),
      );
    });

    test('Decrypting modified ciphertext throws error', () {
      final data = {"value": 999};

      final encrypted = aes.encryptJson(data, keyHex);

      // 暗号文の中身を 1 byte 改ざん（GCM が検出 → エラーになる）
      encrypted[15] ^= 0xFF;

      expect(
        () => aes.decryptJson(encrypted, keyHex),
        throwsA(isA<Exception>()),
      );
    });
  });
}
