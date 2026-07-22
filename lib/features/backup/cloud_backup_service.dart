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
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger.dart';
import '../security/secure_key_service.dart';

const _driveScopes = [drive.DriveApi.driveFileScope];

class CloudBackupService {
  static const _prefsKey = 'cloud_backup_enabled';
  static const _backupFolderName = 'SecondBrain_Backups';

  final SecureKeyService _keyService;
  final GoogleSignIn _googleSignIn;
  AuthClient? _authClient;
  String? _userId;

  CloudBackupService(this._keyService) : _googleSignIn = GoogleSignIn(scopes: _driveScopes);

  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      _userId = account.id;
      final auth = await account.authentication;
      final credential = AccessCredentials(
        AccessToken(
          'Bearer',
          auth.accessToken!,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        _driveScopes,
      );

      final httpClient = http.Client();
      _authClient = authenticatedClient(httpClient, credential);
      AppLogger.info('Google Sign-In successful', tag: 'BACKUP');
      return true;
    } catch (e, stack) {
      AppLogger.error('Google Sign-In failed', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _authClient?.close();
    _authClient = null;
    _userId = null;
    AppLogger.info('Google Sign-Out', tag: 'BACKUP');
  }

  Future<drive.DriveApi> _getDriveApi() async {
    if (_authClient == null) {
      final signed = await signIn();
      if (!signed || _authClient == null) {
        throw Exception('Google Sign-In required');
      }
    }
    return drive.DriveApi(_authClient!);
  }

  Future<String> _getOrCreateBackupFolder(drive.DriveApi api) async {
    final files = await api.files.list(
      "mimeType = 'application/vnd.google-apps.folder' and name = '$_backupFolderName' and trashed = false",
      $fields: 'files(id)',
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

      // Pack [4-byte iv len][iv][4-byte key len][key][ciphertext]
      final ivBytes = Uint8List.fromList(encrypted.iv);
      final keyBytes = Uint8List.fromList(base64Decode(encrypted.keyBase64));
      final cipherBytes = Uint8List.fromList(encrypted.ciphertext);

      final output = BytesBuilder();

      final ivLenBuf = ByteData(4)..setUint32(0, ivBytes.length, Endian.big);
      output.add(ivLenBuf.buffer.asUint8List());
      output.add(ivBytes);

      final keyLenBuf = ByteData(4)..setUint32(0, keyBytes.length, Endian.big);
      output.add(keyLenBuf.buffer.asUint8List());
      output.add(keyBytes);
      output.add(cipherBytes);

      final bytes = output.toBytes();
      final stream = Stream.value(bytes);

      // Delete old backups in Drive
      final oldFiles = await api.files.list(
        "'$folderId' in parents and trashed = false",
        $fields: 'files(id)',
      );
      for (final f in oldFiles.files ?? []) {
        await api.files.delete(f.id!);
      }

      // Upload new backup
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
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
        "'$folderId' in parents and trashed = false",
        $fields: 'files(id,name)',
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

      final allBytes = await media.stream.toBytes();
      final bd = ByteData.view(allBytes.buffer);
      int offset = 0;

      final ivLen = bd.getUint32(offset, Endian.big);
      offset += 4;
      final ivBytes = allBytes.sublist(offset, offset + ivLen);
      offset += ivLen;

      final keyLen = bd.getUint32(offset, Endian.big);
      offset += 4;
      final keyBytes = allBytes.sublist(offset, offset + keyLen);
      offset += keyLen;

      final ciphertext = allBytes.sublist(offset);

      final encrypted = BackupEncrypted(
        ciphertext: ciphertext,
        iv: ivBytes,
        keyBase64: base64Encode(keyBytes),
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

  Future<File> _getDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/second_brain_enc.db');
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
