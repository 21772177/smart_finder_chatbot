import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/settings/settings_service.dart';
import 'package:second_brain/features/analyze/cloud_analysis_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsService', () {
    late SharedPreferences prefs;
    late SettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      // Allow async key loading to complete
      await Future.delayed(const Duration(milliseconds: 50));
    });

    group('defaults', () {
      test('scanOnLike defaults to true', () {
        expect(service.scanOnLike, isTrue);
      });

      test('scanOnSave defaults to true', () {
        expect(service.scanOnSave, isTrue);
      });

      test('enableBuffer defaults to true', () {
        expect(service.enableBuffer, isTrue);
      });

      test('enableCloudLLM defaults to false', () {
        expect(service.enableCloudLLM, isFalse);
      });

      test('enableLocalLLM defaults to false', () {
        expect(service.enableLocalLLM, isFalse);
      });

      test('enableAudioTranscription defaults to false', () {
        expect(service.enableAudioTranscription, isFalse);
      });

      test('llmProvider defaults to gemini', () {
        expect(service.llmProvider, LLMProvider.gemini);
      });

      test('themeMode defaults to system', () {
        expect(service.themeMode, ThemeMode.system);
      });

      test('blockedApps defaults to AppConstants.blockedApps', () {
        expect(service.blockedApps, isNotEmpty);
        expect(service.blockedApps, contains('com.google.android.apps.nbu.paisa.user'));
      });

      test('cloudBackupEnabled defaults to false', () {
        expect(service.cloudBackupEnabled, isFalse);
      });

      test('geminiModel defaults to gemini-2.0-flash', () {
        expect(service.geminiModel, 'gemini-2.0-flash');
      });

      test('openaiModel defaults to gpt-4o-mini', () {
        expect(service.openaiModel, 'gpt-4o-mini');
      });

      test('anthropicModel defaults to claude-3-haiku-20240307', () {
        expect(service.anthropicModel, 'claude-3-haiku-20240307');
      });

      test('dataRetentionDays defaults to 30', () {
        expect(service.dataRetentionDays, 30);
      });
    });

    group('setters persist values', () {
      test('scanOnLike persists', () {
        service.scanOnLike = false;
        expect(service.scanOnLike, isFalse);
        expect(prefs.getBool('scan_on_like'), isFalse);
      });

      test('scanOnSave persists', () {
        service.scanOnSave = false;
        expect(service.scanOnSave, isFalse);
      });

      test('enableBuffer persists', () {
        service.enableBuffer = false;
        expect(service.enableBuffer, isFalse);
      });

      test('enableCloudLLM persists', () {
        service.enableCloudLLM = true;
        expect(service.enableCloudLLM, isTrue);
      });

      test('enableLocalLLM persists', () {
        service.enableLocalLLM = true;
        expect(service.enableLocalLLM, isTrue);
      });

      test('enableAudioTranscription persists', () {
        service.enableAudioTranscription = true;
        expect(service.enableAudioTranscription, isTrue);
      });

      test('llmProvider persists', () {
        service.llmProvider = LLMProvider.openai;
        expect(service.llmProvider, LLMProvider.openai);
        expect(prefs.getString('llm_provider'), 'openai');
      });

      test('themeMode persists', () {
        service.themeMode = ThemeMode.dark;
        expect(service.themeMode, ThemeMode.dark);
      });

      test('cloudBackupEnabled persists', () {
        service.cloudBackupEnabled = true;
        expect(service.cloudBackupEnabled, isTrue);
      });

      test('geminiModel persists', () {
        service.geminiModel = 'gemini-2.5-pro';
        expect(service.geminiModel, 'gemini-2.5-pro');
      });

      test('openaiModel persists', () {
        service.openaiModel = 'gpt-4o';
        expect(service.openaiModel, 'gpt-4o');
      });

      test('anthropicModel persists', () {
        service.anthropicModel = 'claude-3-sonnet';
        expect(service.anthropicModel, 'claude-3-sonnet');
      });

      test('dataRetentionDays persists', () {
        service.dataRetentionDays = 60;
        expect(service.dataRetentionDays, 60);
        expect(prefs.getInt('data_retention_days'), 60);
      });
    });

    group('blocked apps', () {
      test('set blocked apps persists', () {
        final apps = ['com.test.app1', 'com.test.app2'];
        service.blockedApps = apps;
        expect(service.blockedApps, apps);
      });

      test('empty blocked apps falls back to defaults', () {
        service.blockedApps = [];
        expect(service.blockedApps, isNotEmpty);
      });
    });

    group('encrypted API keys', () {
      test('geminiApiKey is null by default', () async {
        expect(service.geminiApiKey, isNull);
      });

      test('set geminiApiKey persists encrypted', () async {
        service.geminiApiKey = 'AIzaSyTest123';
        // Allow async write to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(service.geminiApiKey, 'AIzaSyTest123');
        // Stored value should NOT be plaintext
        final stored = prefs.getString('gemini_api_key');
        expect(stored, isNotNull);
        expect(stored, isNot('AIzaSyTest123'));
      });

      test('clear geminiApiKey by setting null', () async {
        service.geminiApiKey = 'AIzaSyTest123';
        await Future.delayed(const Duration(milliseconds: 50));

        service.geminiApiKey = null;
        await Future.delayed(const Duration(milliseconds: 50));
        expect(service.geminiApiKey, isNull);
      });

      test('openaiApiKey roundtrip', () async {
        service.openaiApiKey = 'sk-test-openai-key';
        await Future.delayed(const Duration(milliseconds: 50));
        expect(service.openaiApiKey, 'sk-test-openai-key');
      });

      test('anthropicApiKey roundtrip', () async {
        service.anthropicApiKey = 'sk-ant-test-key';
        await Future.delayed(const Duration(milliseconds: 50));
        expect(service.anthropicApiKey, 'sk-ant-test-key');
      });
    });
  });
}
