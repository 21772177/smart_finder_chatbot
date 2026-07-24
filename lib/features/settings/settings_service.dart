import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../analyze/cloud_analysis_service.dart';
import '../security/encrypted_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;
  late final EncryptedPreferences _encrypted;

  String? _geminiApiKey;
  String? _openaiApiKey;
  String? _anthropicApiKey;

  SettingsService(this._prefs) {
    _encrypted = EncryptedPreferences(_prefs);
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    _geminiApiKey = await _encrypted.getEncrypted('gemini_api_key');
    _openaiApiKey = await _encrypted.getEncrypted('openai_api_key');
    _anthropicApiKey = await _encrypted.getEncrypted('anthropic_api_key');
  }

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

  String? get geminiApiKey => _geminiApiKey;
  set geminiApiKey(String? value) {
    _geminiApiKey = value;
    _encrypted.setEncrypted('gemini_api_key', value);
  }

  String? get openaiApiKey => _openaiApiKey;
  set openaiApiKey(String? value) {
    _openaiApiKey = value;
    _encrypted.setEncrypted('openai_api_key', value);
  }

  String? get anthropicApiKey => _anthropicApiKey;
  set anthropicApiKey(String? value) {
    _anthropicApiKey = value;
    _encrypted.setEncrypted('anthropic_api_key', value);
  }

  List<String> get blockedApps {
    final saved = _prefs.getStringList('blocked_apps');
    if (saved != null && saved.isNotEmpty) return saved;
    return List.from(AppConstants.blockedApps);
  }
  set blockedApps(List<String> value) => _prefs.setStringList('blocked_apps', value);

  bool get cloudBackupEnabled => _prefs.getBool('cloud_backup_enabled') ?? false;
  set cloudBackupEnabled(bool value) => _prefs.setBool('cloud_backup_enabled', value);

  ThemeMode get themeMode {
    final value = _prefs.getString('theme_mode');
    return ThemeMode.values.asNameMap()[value] ?? ThemeMode.system;
  }
  set themeMode(ThemeMode value) => _prefs.setString('theme_mode', value.name);

  String get geminiModel => _prefs.getString('gemini_model') ?? 'gemini-2.0-flash';
  set geminiModel(String value) => _prefs.setString('gemini_model', value);

  String get openaiModel => _prefs.getString('openai_model') ?? 'gpt-4o-mini';
  set openaiModel(String value) => _prefs.setString('openai_model', value);

  String get anthropicModel => _prefs.getString('anthropic_model') ?? 'claude-3-haiku-20240307';
  set anthropicModel(String value) => _prefs.setString('anthropic_model', value);

  int get dataRetentionDays => _prefs.getInt('data_retention_days') ?? 30;
  set dataRetentionDays(int value) => _prefs.setInt('data_retention_days', value);
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsService(prefs);
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return settings.themeMode;
});
