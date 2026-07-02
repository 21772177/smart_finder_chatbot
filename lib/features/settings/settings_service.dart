import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  bool get scanOnLike => _prefs.getBool('scan_on_like') ?? true;
  set scanOnLike(bool value) => _prefs.setBool('scan_on_like', value);

  bool get scanOnSave => _prefs.getBool('scan_on_save') ?? true;
  set scanOnSave(bool value) => _prefs.setBool('scan_on_save', value);

  bool get enableBuffer => _prefs.getBool('enable_buffer') ?? true;
  set enableBuffer(bool value) => _prefs.setBool('enable_buffer', value);

  bool get enableCloudLLM => _prefs.getBool('enable_cloud_llm') ?? false;
  set enableCloudLLM(bool value) => _prefs.setBool('enable_cloud_llm', value);

  bool get enableWhisper => _prefs.getBool('enable_whisper') ?? false;
  set enableWhisper(bool value) => _prefs.setBool('enable_whisper', value);

  List<String> get blockedApps => _prefs.getStringList('blocked_apps') ?? [];
  set blockedApps(List<String> value) => _prefs.setStringList('blocked_apps', value);
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsService(prefs);
});
