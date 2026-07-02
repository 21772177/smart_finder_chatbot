import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

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

  bool get enableLocalLLM => _prefs.getBool('enable_local_llm') ?? false;
  set enableLocalLLM(bool value) => _prefs.setBool('enable_local_llm', value);

  bool get enableWhisper => _prefs.getBool('enable_whisper') ?? false;
  set enableWhisper(bool value) => _prefs.setBool('enable_whisper', value);

  String? get llmApiKey => _prefs.getString('llm_api_key');
  set llmApiKey(String? value) {
    if (value == null || value.isEmpty) {
      _prefs.remove('llm_api_key');
    } else {
      _prefs.setString('llm_api_key', value);
    }
  }

  List<String> get blockedApps =>
      _prefs.getStringList('blocked_apps') ?? List.from(AppConstants.blockedApps);
  set blockedApps(List<String> value) => _prefs.setStringList('blocked_apps', value);
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsService(prefs);
});
