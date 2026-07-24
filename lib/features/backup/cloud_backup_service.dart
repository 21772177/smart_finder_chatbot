import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/logger.dart';
import '../security/secure_key_service.dart';

class CloudBackupService {
  static const _backupFolderName = 'SecondBrain_Backups';

  GoogleSignInClientAuthorization? _authz;
  final SecureKeyService _keyService;

  CloudBackupService(this._keyService);

  Future<bool> isSignedIn() async {
    try {
      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: [drive.DriveApi.driveFileScope],
      );
      _authz = await account.authorizationClient.authorizeScopes(
        [drive.DriveApi.driveFileScope],
      );
      AppLogger.info('Google Sign-In successful', tag: 'BACKUP');
      return _authz != null;
    } catch (e, stack) {
      AppLogger.error('Google Sign-In failed', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _authz = null;
    AppLogger.info('Google Sign-Out', tag: 'BACKUP');
  }

  Future<drive.DriveApi> _getDriveApi() async {
    if (_authz == null) {
      final signed = await signIn();
      if (!signed || _authz == null) {
        throw Exception('Google Sign-In required');
      }
    }

    final httpClient = http.Client();
    final authClient = authenticatedClient(
      httpClient,
      AccessCredentials(
        AccessToken(
          'Bearer',
          _authz!.accessToken,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        [drive.DriveApi.driveFileScope],
      ),
    );
    return drive.DriveApi(authClient);
  }

  Future<String> _getOrCreateBackupFolder(drive.DriveApi api) async {
    final files = await api.files.list(
      $fields: 'files(id)',
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '$_backupFolderName' and trashed = false",
    );

    if (files.files != null && files.files!.isNotEmpty) {
      return files.files!.first.id!;
    }

    final folder = await api.files.create(
      drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    return folder.id!;
  }

  Future<void> backupDatabase() async {
    try {
      final api = await _getDriveApi();
      final folderId = await _getOrCreateBackupFolder(api);

      final dbFile = File('${(await getApplicationDocumentsDirectory()).path}/second_brain_enc.db');
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      final dbBytes = Uint8List.fromList(await dbFile.readAsBytes());
      final encrypted = await encryptBytes(dbBytes);

      // Encrypt the backup key with the Keystore-protected DB key
      final dbKey = await _keyService.getDbKey();
      final wrappedKey = wrapKey(encrypted.keyBase64, dbKey);

      // Pack [4-byte iv len][iv][4-byte wrapped key len][wrapped key][ciphertext]
      final ivBytes = Uint8List.fromList(encrypted.iv);
      final wrappedKeyBytes = Uint8List.fromList(base64Decode(wrappedKey));
      final cipherBytes = Uint8List.fromList(encrypted.ciphertext);

      final output = BytesBuilder();

      final ivLenBuf = ByteData(4)..setUint32(0, ivBytes.length, Endian.big);
      output.add(ivLenBuf.buffer.asUint8List());
      output.add(ivBytes);

      final keyLenBuf = ByteData(4)..setUint32(0, wrappedKeyBytes.length, Endian.big);
      output.add(keyLenBuf.buffer.asUint8List());
      output.add(wrappedKeyBytes);
      output.add(cipherBytes);

      final bytes = output.toBytes();

      // Delete old backups in Drive
      final oldFiles = await api.files.list(
        $fields: 'files(id)',
        q: "'$folderId' in parents and trashed = false",
      );
      for (final f in oldFiles.files ?? []) {
        await api.files.delete(f.id!);
      }

      // Upload new backup
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final stream = Stream.value(bytes);
      await api.files.create(
        drive.File()
          ..name = 'backup_${timestamp}.enc'
          ..parents = [folderId],
        uploadMedia: drive.Media(stream, bytes.length),
      );

      AppLogger.info('Cloud backup uploaded', tag: 'BACKUP');
    } catch (e, stack) {
      AppLogger.error('Cloud backup failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> restoreDatabase() async {
    try {
      final api = await _getDriveApi();
      final folderId = await _getOrCreateBackupFolder(api);

      final files = await api.files.list(
        $fields: 'files(id,name)',
        q: "'$folderId' in parents and trashed = false",
        orderBy: 'name desc',
      );

      final backups = files.files;
      if (backups == null || backups.isEmpty) {
        throw Exception('No backups found on Google Drive');
      }

      final latest = backups.first;
      final media = await api.files.get(
        latest.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Collect stream into bytes
      final chunks = <List<int>>[];
      await for (final chunk in media.stream) {
        chunks.add(chunk);
      }
      final allBytes = _concatenateChunks(chunks);

      final bd = ByteData.view(allBytes.buffer);
      int offset = 0;

      final ivLen = bd.getUint32(offset, Endian.big);
      offset += 4;
      final ivBytes = allBytes.sublist(offset, offset + ivLen);
      offset += ivLen;

      final keyLen = bd.getUint32(offset, Endian.big);
      offset += 4;
      final wrappedKeyBytes = allBytes.sublist(offset, offset + keyLen);
      offset += keyLen;

      final ciphertext = allBytes.sublist(offset);

      // Unwrap the backup key with the Keystore-protected DB key
      final dbKey = await _keyService.getDbKey();
      final keyBase64 = unwrapKey(base64Encode(wrappedKeyBytes), dbKey);

      final encrypted = BackupEncrypted(
        ciphertext: ciphertext,
        iv: ivBytes,
        keyBase64: keyBase64,
      );

      final decrypted = await decryptBytes(encrypted);

      final dbFile = File('${(await getApplicationDocumentsDirectory()).path}/second_brain_enc.db');
      await dbFile.writeAsBytes(decrypted);

      AppLogger.info('Cloud restore completed', tag: 'BACKUP');
    } catch (e, stack) {
      AppLogger.error('Cloud restore failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Uint8List _concatenateChunks(List<List<int>> chunks) {
    int totalLength = 0;
    for (final chunk in chunks) {
      totalLength += chunk.length;
    }
    final result = Uint8List(totalLength);
    int offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  /// Wraps the backup AES key using the Keystore-protected DB key.
  /// Format: [4-byte iv len][iv][ciphertext]
  String wrapKey(String backupKeyBase64, String dbKeyHex) {
    final backupKeyBytes = base64Decode(backupKeyBase64);
    final wrappingKey = _deriveWrappingKey(dbKeyHex);

    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));

    final key = Key(Uint8List.fromList(wrappingKey));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encryptBytes(backupKeyBytes, iv: iv);

    final output = BytesBuilder();
    final ivLenBuf = ByteData(4)..setUint32(0, ivBytes.length, Endian.big);
    output.add(ivLenBuf.buffer.asUint8List());
    output.add(ivBytes);
    output.add(encrypted.bytes);
    return base64Encode(output.toBytes());
  }

  /// Unwraps the backup AES key using the Keystore-protected DB key.
  String unwrapKey(String wrappedKeyBase64, String dbKeyHex) {
    final wrappedBytes = base64Decode(wrappedKeyBase64);
    final wrappingKey = _deriveWrappingKey(dbKeyHex);

    final bd = ByteData.view(wrappedBytes.buffer);
    int offset = 0;
    final ivLen = bd.getUint32(offset, Endian.big);
    offset += 4;
    final ivBytes = wrappedBytes.sublist(offset, offset + ivLen);
    offset += ivLen;
    final ciphertext = wrappedBytes.sublist(offset);

    final key = Key(Uint8List.fromList(wrappingKey));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final decrypted = encrypter.decryptBytes(
      Encrypted(Uint8List.fromList(ciphertext)),
      iv: iv,
    );
    return base64Encode(decrypted);
  }

  List<int> _deriveWrappingKey(String dbKeyHex) {
    final keyChars = '0123456789abcdef';
    final bytes = <int>[];
    for (var i = 0; i < dbKeyHex.length && bytes.length < 32; i += 2) {
      final hi = keyChars.indexOf(dbKeyHex[i]);
      final lo = (i + 1 < dbKeyHex.length) ? keyChars.indexOf(dbKeyHex[i + 1]) : 0;
      if (hi >= 0 && lo >= 0) {
        bytes.add((hi << 4) | lo);
      }
    }
    while (bytes.length < 32) {
      bytes.add(0);
    }
    return bytes;
  }

  Future<BackupEncrypted> encryptBytes(Uint8List plainBytes) async {
    try {
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

  Future<Uint8List> decryptBytes(BackupEncrypted encrypted) async {
    try {
      final keyBytes = base64Decode(encrypted.keyBase64);
      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV(Uint8List.fromList(encrypted.iv));
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      final decrypted = encrypter.decryptBytes(
        Encrypted(Uint8List.fromList(encrypted.ciphertext)),
        iv: iv,
      );
      return Uint8List.fromList(decrypted);
    } catch (e, stack) {
      AppLogger.error('Failed to decrypt backup data', error: e, stackTrace: stack);
      rethrow;
    }
  }

}

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
