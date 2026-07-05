import 'dart:io';
import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/secure_key_service.dart';

class CloudBackupService {
  static const _driveScope = drive.DriveApi.driveAppdataScope;
  static const _prefsKey = 'cloud_backup_enabled';

  final SecureKeyService _keyService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [_driveScope],
  );

  CloudBackupService(this._keyService);

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<auth.AuthClient?> _getAuthClient() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    if (authHeaders == null) return null;

    return auth.clientViaUserConsent(
      auth.ClientId('client_id', 'client_secret'),
      _driveScope,
      (url) async => throw Exception('User consent required'),
    );
  }

  Future<void> backupDatabase() async {
    final authClient = await _getAuthClient();
    if (authClient == null) throw Exception('Not signed in to Google Drive');

    final driveApi = drive.DriveApi(authClient);

    final dbFile = await _getDatabaseFile();
    if (!await dbFile.exists()) throw Exception('Database file not found');

    final key = await _keyService.getDbKey();
    final encryptedBytes = await _encryptFile(dbFile, key);

    final media = drive.Media(
      Stream.value(encryptedBytes),
      encryptedBytes.length,
    );

    final file = drive.File()
      ..name = 'second_brain_backup_${DateTime.now().toIso8601String()}.enc'
      ..parents = ['appDataFolder'];

    await driveApi.files.create(file, uploadMedia: media);
  }

  Future<void> restoreDatabase() async {
    final authClient = await _getAuthClient();
    if (authClient == null) throw Exception('Not signed in to Google Drive');

    final driveApi = drive.DriveApi(authClient);

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      throw Exception('No backup found');
    }

    final latestBackup = fileList.files!.first;
    final media = await driveApi.files.get(latestBackup.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    final encryptedBytes = <int>[];
    await for (final chunk in media.stream) {
      encryptedBytes.addAll(chunk);
    }

    final key = await _keyService.getDbKey();
    final decryptedBytes = await _decryptBytes(encryptedBytes, key);

    final dbFile = await _getDatabaseFile();
    await dbFile.writeAsBytes(decryptedBytes, flush: true);
  }

  Future<File> _getDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/second_brain_enc.db');
  }

  Future<Uint8List> _encryptFile(File file, String key) async {
    final bytes = await file.readAsBytes();
    return _encryptBytes(bytes, key);
  }

  Future<Uint8List> _encryptBytes(Uint8List bytes, String key) async {
    // Simple XOR encryption for demonstration
    // In production, use proper AES-GCM
    final keyBytes = key.codeUnits;
    final result = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      result[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return result;
  }

  Future<Uint8List> _decryptBytes(List<int> encrypted, String key) async {
    // XOR is symmetric
    return _encryptBytes(Uint8List.fromList(encrypted), key);
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