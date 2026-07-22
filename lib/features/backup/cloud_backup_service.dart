import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger.dart';
import '../security/secure_key_service.dart';

class CloudBackupService {
  static const _prefsKey = 'cloud_backup_enabled';

  final SecureKeyService _keyService;

  CloudBackupService(this._keyService);

  Future<bool> isSignedIn() async {
    // Placeholder - requires Google Sign-In integration
    return false;
  }

  Future<bool> signIn() async {
    // Placeholder - requires Google Sign-In integration
    return false;
  }

  Future<void> signOut() async {
    // Placeholder
  }

  Future<void> backupDatabase() async {
    throw UnimplementedError('Google Drive backup not yet implemented');
  }

  Future<void> restoreDatabase() async {
    throw UnimplementedError('Google Drive restore not yet implemented');
  }

  Future<File> _getDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/second_brain_enc.db');
  }

  /// Encrypt bytes using AES-256-GCM with a random key derived from the secure DB key.
  /// Returns a [BackupEncrypted] containing the ciphertext, IV, and encrypted key.
  Future<BackupEncrypted> encryptBytes(Uint8List plainBytes) async {
    try {
      // Generate a random 32-byte AES key and 16-byte IV
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));

      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV(Uint8List.fromList(ivBytes));
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

      return BackupEncrypted(
        ciphertext: encrypted.bytes,
        iv: ivBytes,
        keyBase64: base64Encode(keyBytes),
      );
    } catch (e, stack) {
      AppLogger.error('Failed to encrypt backup data', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Decrypt bytes using AES-256-GCM with the provided key and IV.
  Future<Uint8List> decryptBytes(BackupEncrypted encrypted) async {
    try {
      final keyBytes = base64Decode(encrypted.keyBase64);
      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV(Uint8List.fromList(encrypted.iv));
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      return Uint8List.fromList(encrypter.decryptBytes(Encrypted(encrypted.ciphertext), iv: iv));
    } catch (e, stack) {
      AppLogger.error('Failed to decrypt backup data', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<bool> isBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}

/// Encrypted backup data with its IV and base64-encoded key.
class BackupEncrypted {
  final List<int> ciphertext;
  final List<int> iv;
  final String keyBase64;

  const BackupEncrypted({
    required this.ciphertext,
    required this.iv,
    required this.keyBase64,
  });
}
