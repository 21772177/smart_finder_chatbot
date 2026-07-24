import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/security/encrypted_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EncryptedPreferences', () {
    late SharedPreferences prefs;
    late EncryptedPreferences encrypted;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      encrypted = EncryptedPreferences(prefs);
    });

    group('encryptValue / decryptValue', () {
      test('roundtrip preserves plaintext', () async {
        final ciphertext = await encrypted.encryptValue('my-secret-api-key');
        expect(ciphertext, isNotEmpty);
        expect(ciphertext, isNot('my-secret-api-key'));

        final decrypted = await encrypted.decryptValue(ciphertext);
        expect(decrypted, 'my-secret-api-key');
      });

      test('roundtrip with empty string', () async {
        final ciphertext = await encrypted.encryptValue('');
        final decrypted = await encrypted.decryptValue(ciphertext);
        expect(decrypted, '');
      });

      test('roundtrip with long text', () async {
        final longText = 'A' * 10000;
        final ciphertext = await encrypted.encryptValue(longText);
        final decrypted = await encrypted.decryptValue(ciphertext);
        expect(decrypted, longText);
      });

      test('roundtrip with special characters', () async {
        final special = 'key-with/special+chars=123&more';
        final ciphertext = await encrypted.encryptValue(special);
        final decrypted = await encrypted.decryptValue(ciphertext);
        expect(decrypted, special);
      });

      test('different encryptions produce different ciphertext (random IV)', () async {
        final c1 = await encrypted.encryptValue('same-value');
        final c2 = await encrypted.encryptValue('same-value');
        expect(c1, isNot(c2));
      });

      test('decryptValue returns null for invalid base64', () async {
        final result = await encrypted.decryptValue('not-valid-base64!!!');
        expect(result, isNull);
      });
    });

    group('setEncrypted / getEncrypted', () {
      test('set and get encrypted value', () async {
        await encrypted.setEncrypted('api_key', 'sk-test-123');
        final result = await encrypted.getEncrypted('api_key');
        expect(result, 'sk-test-123');
      });

      test('setEncrypted with null removes key', () async {
        await encrypted.setEncrypted('api_key', 'sk-test-123');
        expect(await encrypted.getEncrypted('api_key'), 'sk-test-123');

        await encrypted.setEncrypted('api_key', null);
        expect(await encrypted.getEncrypted('api_key'), isNull);
      });

      test('setEncrypted with empty string removes key', () async {
        await encrypted.setEncrypted('api_key', 'value');
        await encrypted.setEncrypted('api_key', '');
        expect(await encrypted.getEncrypted('api_key'), isNull);
      });

      test('getEncrypted returns null for missing key', () async {
        final result = await encrypted.getEncrypted('nonexistent');
        expect(result, isNull);
      });

      test('stored value is not plaintext in SharedPreferences', () async {
        await encrypted.setEncrypted('secret_key', 'my-api-key-12345');
        final stored = prefs.getString('secret_key');
        expect(stored, isNotNull);
        expect(stored, isNot('my-api-key-12345'));
        expect(stored!.length, greaterThan(10));
      });
    });

    group('key persistence', () {
      test('same EncryptedPreferences instance uses cached key', () async {
        await encrypted.setEncrypted('key1', 'value1');
        final result1 = await encrypted.getEncrypted('key1');

        // Second instance should load the same key from SharedPreferences
        final encrypted2 = EncryptedPreferences(prefs);
        final result2 = await encrypted2.getEncrypted('key1');

        expect(result1, result2);
      });

      test('encryption key is stored in SharedPreferences', () async {
        await encrypted.setEncrypted('key1', 'value1');
        final storedKey = prefs.getString('second_brain_enc_key');
        expect(storedKey, isNotNull);
        expect(storedKey!.length, greaterThan(20));
      });
    });
  });
}
