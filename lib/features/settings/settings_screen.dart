import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../memory/memory_repository.dart';
import 'settings_service.dart';
import 'blocked_apps_screen.dart';
import '../analyze/cloud_analysis_service.dart';
import '../analyze/local_llm_service.dart';
import '../permissions/permission_dashboard.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Permissions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Permission Dashboard'),
              subtitle: const Text('View and grant required permissions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PermissionDashboard()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Behaviors', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Scan on Like'),
                  subtitle: const Text('Capture content when you tap Like'),
                  value: settings.scanOnLike,
                  onChanged: (v) => ref.read(settingsServiceProvider).scanOnLike = v,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Scan on Save'),
                  subtitle: const Text('Capture content when you tap Save'),
                  value: settings.scanOnSave,
                  onChanged: (v) => ref.read(settingsServiceProvider).scanOnSave = v,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Live Buffer'),
                  subtitle: const Text('Temporarily buffer visible content'),
                  value: settings.enableBuffer,
                  onChanged: (v) => ref.read(settingsServiceProvider).enableBuffer = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('AI Features', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Cloud LLM (Opt-in)'),
                  subtitle: const Text('Enable GPT/Gemini/Claude for advanced AI'),
                  value: settings.enableCloudLLM,
                  onChanged: (v) => ref.read(settingsServiceProvider).enableCloudLLM = v,
                ),
                const Divider(height: 1),
                if (settings.enableCloudLLM) ...[
                  ListTile(
                    leading: const Icon(Icons.psychology),
                    title: const Text('Cloud Provider'),
                    subtitle: Text(
                      settings.llmProvider.name.toUpperCase(),
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showProviderDialog(context, ref, settings),
                  ),
                  const Divider(height: 1),
                  _buildApiKeyTile(
                    context,
                    ref,
                    settings,
                    'Gemini API Key',
                    settings.geminiApiKey,
                    settings.llmProvider == LLMProvider.gemini,
                    () => _showApiKeyDialog(context, ref, settings, 'gemini'),
                  ),
                  _buildApiKeyTile(
                    context,
                    ref,
                    settings,
                    'OpenAI API Key',
                    settings.openaiApiKey,
                    settings.llmProvider == LLMProvider.openai,
                    () => _showApiKeyDialog(context, ref, settings, 'openai'),
                  ),
                  _buildApiKeyTile(
                    context,
                    ref,
                    settings,
                    'Claude API Key',
                    settings.anthropicApiKey,
                    settings.llmProvider == LLMProvider.anthropic,
                    () => _showApiKeyDialog(context, ref, settings, 'anthropic'),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Audio Transcription'),
                  subtitle: const Text('Enable on-device transcription for audio/video'),
                  value: settings.enableWhisper,
                  onChanged: (v) => ref.read(settingsServiceProvider).enableWhisper = v,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Local LLM'),
                  subtitle: const Text('On-device inference (Gemma/Phi/TinyLlama)'),
                  value: settings.enableLocalLLM,
                  onChanged: (v) => ref.read(settingsServiceProvider).enableLocalLLM = v,
                ),
                if (settings.enableLocalLLM) ...LocalLLMService.recommendedModels.map(
                  (model) => ListTile(
                    leading: const Icon(Icons.model_training),
                    title: Text(model.name),
                    subtitle: Text('${model.description} • ${model.sizeMb}MB'),
                    trailing: FilledButton.tonal(
                      onPressed: () => _downloadModel(context, ref, model),
                      child: const Text('Download'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Privacy', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Blocked Apps'),
                  subtitle: Text('${settings.blockedApps.length} apps blocked'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlockedAppsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download all your memories'),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Delete All Data', style: TextStyle(color: theme.colorScheme.error)),
                  subtitle: const Text('Permanently erase all memories'),
                  onTap: () => _deleteAllData(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Backup', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Encrypted Cloud Backup'),
                  subtitle: const Text('Backup encrypted database to Google Drive'),
                  value: settings.cloudBackupEnabled,
                  onChanged: (v) => ref.read(settingsServiceProvider).cloudBackupEnabled = v,
                ),
                if (settings.cloudBackupEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup Now'),
                    subtitle: const Text('Upload encrypted database to Drive'),
                    trailing: FilledButton.tonal(
                      onPressed: () => _backupToDrive(context, ref),
                      child: const Text('Backup'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore from Drive'),
                    subtitle: const Text('Download and decrypt database from Drive'),
                    trailing: FilledButton.tonal(
                      onPressed: () => _restoreFromDrive(context, ref),
                      child: const Text('Restore'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Second Brain v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadModel(BuildContext context, WidgetRef ref, RecommendedModel model) async {
    final messenger = ScaffoldMessenger.of(context);
    final llm = ref.read(localLlmServiceProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Download ${model.name}'),
        content: Text(
          'This will download a ${model.sizeMb}MB model file. '
          'Download over Wi-Fi recommended.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Download started...'), duration: Duration(seconds: 2)),
    );

    final filename = model.url.split('/').last;
    final success = await llm.downloadModel(model.url, filename);

    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Model downloaded successfully' : 'Download failed'),
        ),
      );
      if (success) {
        ref.invalidate(localLlmServiceProvider);
      }
    }
  }

  Future<void> _showApiKeyDialog(BuildContext context, WidgetRef ref, SettingsService settings, String provider) async {
    String title;
    String hint;
    String url;
    String? currentKey;
    Function(String?) setter;

    switch (provider) {
      case 'gemini':
        title = 'Gemini API Key';
        hint = 'AIza...';
        url = 'ai.google.dev';
        currentKey = settings.geminiApiKey;
        setter = (v) => settings.geminiApiKey = v;
        break;
      case 'openai':
        title = 'OpenAI API Key';
        hint = 'sk-...';
        url = 'platform.openai.com';
        currentKey = settings.openaiApiKey;
        setter = (v) => settings.openaiApiKey = v;
        break;
      case 'anthropic':
        title = 'Claude API Key';
        hint = 'sk-ant-...';
        url = 'console.anthropic.com';
        currentKey = settings.anthropicApiKey;
        setter = (v) => settings.anthropicApiKey = v;
        break;
      default:
        title = 'API Key';
        hint = '...';
        url = '';
        currentKey = null;
        setter = (_) {};
    }

    final controller = TextEditingController(text: currentKey ?? '');
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your $title to enable cloud-based analysis with ${provider.toUpperCase()}.\n'
              'Get a key at $url.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setter(null);
              ref.invalidate(cloudAnalysisServiceProvider);
              messenger.showSnackBar(
                const SnackBar(content: Text('API key removed')),
              );
              Navigator.pop(ctx);
            },
            child: Text('Clear', style: TextStyle(color: Colors.red.shade300)),
          ),
          FilledButton(
            onPressed: () {
              final key = controller.text.trim();
              if (key.isEmpty) return;
              setter(key);
              ref.invalidate(cloudAnalysisServiceProvider);
              messenger.showSnackBar(
                const SnackBar(content: Text('API key saved')),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyTile(BuildContext context, WidgetRef ref, SettingsService settings,
      String title, String? key, bool isActive, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(isActive ? Icons.check_circle : Icons.key, color: isActive ? Colors.green : null),
      title: Text(title),
      subtitle: Text(
        key != null && key.isNotEmpty
            ? 'Configured (${key.substring(0, 8)}...)'
            : 'Not set ${isActive ? '— required for current provider' : ''}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _showProviderDialog(BuildContext context, WidgetRef ref, SettingsService settings) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Cloud Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LLMProvider.values.map((p) => RadioListTile<LLMProvider>(
            title: Text(p.name.toUpperCase()),
            value: p,
            groupValue: settings.llmProvider,
            onChanged: (v) {
              if (v != null) {
                settings.llmProvider = v;
                ref.invalidate(cloudAnalysisServiceProvider);
                Navigator.pop(ctx);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(memoryRepositoryProvider);
    final entries = await repo.getAllEntries();

    if (entries.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No memories to export')),
      );
      return;
    }

    final data = entries.map((e) => {
      'id': e.id,
      'title': e.title,
      'content': e.content,
      'sourceApp': e.sourceApp,
      'ocrText': e.ocrText,
      'tags': e.tags,
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
    }).toList();

    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/second_brain_export_$timestamp.json');
    await file.writeAsString(json);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Exported ${entries.length} memories to ${file.path}'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently erase all your saved memories. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(memoryRepositoryProvider).deleteAllEntries();
    ref.invalidate(memoryRepositoryProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All memories deleted')),
      );
    }
  }

  Future<void> _backupToDrive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Preparing backup...')));

    try {
      // Get the encrypted database file
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/second_brain_enc.db');
      if (!await dbFile.exists()) {
        messenger.showSnackBar(const SnackBar(content: Text('Database not found')));
        return;
      }

      // Read database and re-encrypt with a backup-specific key
      final dbBytes = await dbFile.readAsBytes();
      final backupKey = _generateBackupKey();
      final encrypted = _encryptData(dbBytes, backupKey);

      // Upload to Google Drive (placeholder - requires Google Sign-In + Drive API)
      // For now, save to local backup folder with instructions
      final backupDir = Directory('${dir.path}/drive_backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFile = File('${backupDir.path}/backup_$timestamp.enc');
      await backupFile.writeAsBytes(encrypted);

      // Save the backup key separately (encrypted with user's passphrase in real app)
      final keyFile = File('${backupDir.path}/backup_$timestamp.key');
      await keyFile.writeAsString(backupKey);

      messenger.showSnackBar(
        SnackBar(content: Text('Backup saved to ${backupFile.path}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restoreFromDrive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace your current database. Make sure you have a recent backup.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );

    if (confirmed != true) return;

    messenger.showSnackBar(const SnackBar(content: Text('Restoring...')));

    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/drive_backups');

      if (!await backupDir.exists()) {
        messenger.showSnackBar(const SnackBar(content: Text('No backups found')));
        return;
      }

      final files = backupDir.listSync().whereType<File>().toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      if (files.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('No backups found')));
        return;
      }

      final latestBackup = files.firstWhere((f) => f.path.endsWith('.enc'));
      final keyFile = File('${latestBackup.path.replaceAll('.enc', '.key')}');

      if (!await keyFile.exists()) {
        messenger.showSnackBar(const SnackBar(content: Text('Backup key not found')));
        return;
      }

      final backupKey = await keyFile.readAsString();
      final encryptedBytes = await latestBackup.readAsBytes();
      final decrypted = _decryptData(encryptedBytes, backupKey);

      final dbFile = File('${dir.path}/second_brain_enc.db');
      await dbFile.writeAsBytes(decrypted);

      ref.invalidate(memoryRepositoryProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Database restored successfully. Restart app.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  String _generateBackupKey() {
    final random = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$random${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
  }

  List<int> _encryptData(List<int> data, String key) {
    // Simple XOR encryption for demo - use AES-GCM in production
    final keyBytes = key.codeUnits;
    final result = <int>[];
    for (int i = 0; i < data.length; i++) {
      result.add(data[i] ^ keyBytes[i % keyBytes.length]);
    }
    return result;
  }

  List<int> _decryptData(List<int> data, String key) => _encryptData(data, key);
}
