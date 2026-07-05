import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../analyze/cloud_analysis_service.dart';

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

  LLMProvider get llmProvider => LLMProvider.values.byName(_prefs.getString('llm_provider') ?? 'gemini');
  set llmProvider(LLMProvider value) => _prefs.setString('llm_provider', value.name);

  String? get geminiApiKey => _prefs.getString('gemini_api_key');
  set geminiApiKey(String? value) {
    if (value == null || value.isEmpty) {
      _prefs.remove('gemini_api_key');
    } else {
      _prefs.setString('gemini_api_key', value);
    }
  }

  String? get openaiApiKey => _prefs.getString('openai_api_key');
  set openaiApiKey(String? value) {
    if (value == null || value.isEmpty) {
      _prefs.remove('openai_api_key');
    } else {
      _prefs.setString('openai_api_key', value);
    }
  }

  String? get anthropicApiKey => _prefs.getString('anthropic_api_key');
  set anthropicApiKey(String? value) {
    if (value == null || value.isEmpty) {
      _prefs.remove('anthropic_api_key');
    } else {
      _prefs.setString('anthropic_api_key', value);
    }
  }

  // Legacy getter for backwards compatibility
  String? get llmApiKey => _prefs.getString('llm_api_key') ?? geminiApiKey;
  set llmApiKey(String? value) => geminiApiKey = value;

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
