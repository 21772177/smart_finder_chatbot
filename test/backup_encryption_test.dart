import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/backup/cloud_backup_service.dart';
import 'package:second_brain/features/security/secure_key_service.dart';

void main() {
  group('BackupEncrypted', () {
    test('holds ciphertext, iv, and keyBase64', () {
      final enc = BackupEncrypted(
        ciphertext: [1, 2, 3, 4],
        iv: [5, 6, 7, 8],
        keyBase64: 'dGVzdGtleQ==',
      );

      expect(enc.ciphertext, [1, 2, 3, 4]);
      expect(enc.iv, [5, 6, 7, 8]);
      expect(enc.keyBase64, 'dGVzdGtleQ==');
    });

    test('is const constructable', () {
      const enc = BackupEncrypted(
        ciphertext: [1],
        iv: [2],
        keyBase64: 'key',
      );

      expect(enc.ciphertext, [1]);
    });
  });

  group('CloudBackupService encryption', () {
    late CloudBackupService service;

    setUp(() {
      service = CloudBackupService(_FakeSecureKeyService());
    });

    test('encryptBytes returns BackupEncrypted with correct structure', () async {
      final plain = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
      final encrypted = await service.encryptBytes(plain);

      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.iv.length, 16);
      expect(encrypted.keyBase64, isNotEmpty);
    });

    test('encryptBytes produces different ciphertext each time (random key/IV)', () async {
      final plain = Uint8List.fromList([1, 2, 3, 4, 5]);
      final e1 = await service.encryptBytes(plain);
      final e2 = await service.encryptBytes(plain);

      expect(e1.ciphertext, isNot(equals(e2.ciphertext)));
    });

    test('decryptBytes reverses encryptBytes', () async {
      final plain = Uint8List.fromList([10, 20, 30, 40, 50, 60]);
      final encrypted = await service.encryptBytes(plain);
      final decrypted = await service.decryptBytes(encrypted);

      expect(decrypted, equals(plain));
    });

    test('decryptBytes fails with wrong key', () async {
      final plain = Uint8List.fromList([1, 2, 3]);
      final encrypted = await service.encryptBytes(plain);

      final wrongEncrypted = BackupEncrypted(
        ciphertext: encrypted.ciphertext,
        iv: encrypted.iv,
        keyBase64: 'AAAA', // wrong key
      );

      expect(
        () => service.decryptBytes(wrongEncrypted),
        throwsA(anything),
      );
    });

    test('decryptBytes fails with wrong IV', () async {
      final plain = Uint8List.fromList([1, 2, 3]);
      final encrypted = await service.encryptBytes(plain);

      final wrongIvEncrypted = BackupEncrypted(
        ciphertext: encrypted.ciphertext,
        iv: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        keyBase64: encrypted.keyBase64,
      );

      expect(
        () => service.decryptBytes(wrongIvEncrypted),
        throwsA(anything),
      );
    });

    test('encrypt large payload', () async {
      final plain = Uint8List(100000);
      for (int i = 0; i < plain.length; i++) {
        plain[i] = i % 256;
      }

      final encrypted = await service.encryptBytes(plain);
      final decrypted = await service.decryptBytes(encrypted);

      expect(decrypted, equals(plain));
    });

    test('encrypt empty payload', () async {
      final plain = Uint8List(0);
      final encrypted = await service.encryptBytes(plain);
      final decrypted = await service.decryptBytes(encrypted);

      expect(decrypted, equals(plain));
    });
  });
}

class _FakeSecureKeyService implements SecureKeyService {
  @override
  Future<String> getDbKey() async => 'test-db-key-for-testing';
}
