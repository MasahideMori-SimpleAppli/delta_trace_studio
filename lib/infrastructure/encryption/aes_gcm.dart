import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';

class AesGcm {
  /// (en) It is encrypted using AES-GCM. The nonce(12 bytes) is added to the beginning of the bytecode.
  /// AAD is not currently supported.
  ///
  /// (ja) AES-GCMで暗号化します。nonce(12 bytes)はバイトコード先頭に付与する方式です。
  /// 現在、AADには対応していません。
  ///
  /// * [data] : Data obtained by converting DeltaTraceDatabase to Dict.
  /// * [keyHex]: AES key (32 bytes will be AES-256)
  Uint8List encryptJson(Map<String, dynamic> data, String keyHex) {
    final key = Uint8List.fromList(
      List<int>.generate(
        keyHex.length ~/ 2,
        (i) => int.parse(keyHex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
    // 推奨 nonce = 12 bytes
    final nonce = Uint8List(12);
    final rnd = Random.secure();
    for (int i = 0; i < nonce.length; i++) {
      nonce[i] = rnd.nextInt(256);
    }
    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    final gcm = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128, // tag length (bits)
      nonce, // IV / nonce
      Uint8List(0), // AAD (None と同等)
    );
    gcm.init(true, params);
    // 暗号化
    final cipherText = gcm.process(Uint8List.fromList(jsonBytes));
    return Uint8List.fromList(nonce + cipherText);
  }

  /// (en) Decrypt using AES GCM. The nonce (12 bytes) is read as the method given at the beginning of the bytecode.
  /// AAD is not currently supported.
  ///
  /// (ja) AES GCMで復号化します。nonce(12 bytes)はバイトコード先頭に付与されている方式として読み込みます。
  /// 現在、AADには対応していません。
  ///
  /// * [data] : The encrypted bytes, which must be formatted with a leading nonce.
  /// * [keyHex] : AES key (32 bytes will be AES-256)
  Map<String, dynamic> decryptJson(Uint8List data, String keyHex) {
    final key = Uint8List.fromList(
      List<int>.generate(
        keyHex.length ~/ 2,
        (i) => int.parse(keyHex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
    if (data.length < 12 + 16) {
      throw Exception("Data too short: not in nonce + ciphertext+tag format.");
    }
    final nonce = data.sublist(0, 12); // 12 bytes
    final cipherBytes = data.sublist(12); // ciphertext + tag
    final gcm = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128, // tag length
      nonce,
      Uint8List(0), // AAD (None と同等)
    );
    gcm.init(false, params);
    // 復号化
    final decrypted = gcm.process(cipherBytes);
    return json.decode(utf8.decode(decrypted)) as Map<String, dynamic>;
  }
}
