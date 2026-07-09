/// Chiffrement local AES-256 (CBC + clé 256 bits) de l'historique d'analyses.
///
/// Preuve « les données restent sur l'appareil » exigée par le Done du MVP :
/// rien ne quitte le téléphone, et ce qui est stocké est illisible sans la clé.
/// En production : clé dans le Keystore Android / Secure Enclave, ici clé
/// générée par installation et stockée localement (démo).
library;

import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';

class EncryptedBlob {
  const EncryptedBlob({required this.iv, required this.ciphertextB64});

  final String iv;
  final String ciphertextB64;
}

class CryptoService {
  CryptoService._(this._key, this.keyFingerprint);

  static const _keyPref = 'wariguard.aes.key';
  final enc.Key _key;

  /// Empreinte courte de la clé, affichable sans révéler la clé.
  final String keyFingerprint;

  static Future<CryptoService> init() async {
    final prefs = await SharedPreferences.getInstance();
    var keyB64 = prefs.getString(_keyPref);
    if (keyB64 == null) {
      keyB64 = enc.Key.fromSecureRandom(32).base64; // 32 octets = AES-256
      await prefs.setString(_keyPref, keyB64);
    }
    final key = enc.Key.fromBase64(keyB64);
    final digest = key.bytes.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
    final fp = digest.toRadixString(16).padLeft(8, '0').toUpperCase();
    return CryptoService._(key, 'SHA·$fp');
  }

  EncryptedBlob encryptJson(Object json) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonEncode(json), iv: iv);
    return EncryptedBlob(iv: iv.base64, ciphertextB64: encrypted.base64);
  }

  dynamic decryptJson(EncryptedBlob blob) {
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final clear = encrypter.decrypt64(blob.ciphertextB64, iv: enc.IV.fromBase64(blob.iv));
    return jsonDecode(clear);
  }
}
