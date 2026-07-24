import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger.dart';

class EncryptedPreferences {
  static const _keyPref = 'second_brain_enc_key';
  final SharedPreferences _prefs;
  String? _cachedKey;

  EncryptedPreferences(this._prefs);

  Future<String> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final existing = _prefs.getString(_keyPref);
    if (existing != null && existing.isNotEmpty) {
      _cachedKey = existing;
      return existing;
    }

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final keyBase64 = base64Encode(keyBytes);
    await _prefs.setString(_keyPref, keyBase64);
    _cachedKey = keyBase64;
    AppLogger.info('Generated new encryption key for preferences', tag: 'SECURITY');
    return keyBase64;
  }

  Future<String> encryptValue(String plaintext) async {
    final keyBase64 = await _getOrCreateKey();
    final key = Key(base64Decode(keyBase64));
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Format: [4-byte iv len][iv][ciphertext]
    final output = BytesBuilder();
    final ivLenBuf = ByteData(4)..setUint32(0, iv.bytes.length, Endian.big);
    output.add(ivLenBuf.buffer.asUint8List());
    output.add(iv.bytes);
    output.add(encrypted.bytes);
    return base64Encode(output.toBytes());
  }

  Future<String?> decryptValue(String encryptedBase64) async {
    try {
      final keyBase64 = await _getOrCreateKey();
      final allBytes = base64Decode(encryptedBase64);
      final bd = ByteData.view(allBytes.buffer);
      int offset = 0;

      final ivLen = bd.getUint32(offset, Endian.big);
      offset += 4;
      final ivBytes = allBytes.sublist(offset, offset + ivLen);
      offset += ivLen;
      final ciphertext = allBytes.sublist(offset);

      final key = Key(base64Decode(keyBase64));
      final iv = IV(ivBytes);
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      return encrypter.decrypt(Encrypted(ciphertext), iv: iv);
    } catch (e, stack) {
      AppLogger.error('Failed to decrypt preference value', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> setEncrypted(String prefsKey, String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(prefsKey);
    } else {
      final encrypted = await encryptValue(value);
      await _prefs.setString(prefsKey, encrypted);
    }
  }

  Future<String?> getEncrypted(String prefsKey) async {
    final encrypted = _prefs.getString(prefsKey);
    if (encrypted == null || encrypted.isEmpty) return null;
    return decryptValue(encrypted);
  }
}
