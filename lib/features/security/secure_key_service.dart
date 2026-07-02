import 'package:flutter/services.dart';

class SecureKeyService {
  static const _channel = MethodChannel('com.secondbrain/secure_key');

  Future<String> getDbKey() async {
    final key = await _channel.invokeMethod<String>('getDbKey');
    if (key == null || key.isEmpty) {
      throw Exception('Failed to retrieve database key from secure storage');
    }
    return key;
  }
}
