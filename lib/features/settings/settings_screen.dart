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
                SwitchListTile(
                  title: const Text('Audio Transcription'),
                  subtitle: const Text('Enable Whisper for audio/video content'),
                  value: settings.enableWhisper,
                  onChanged: (v) => ref.read(settingsServiceProvider).enableWhisper = v,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Gemini API Key'),
                  subtitle: Text(
                    settings.llmApiKey != null && settings.llmApiKey!.isNotEmpty
                        ? 'Configured (${settings.llmApiKey!.substring(0, 8)}...)'
                        : 'Not set — required for cloud analysis',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showApiKeyDialog(context, ref, settings),
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

  Future<void> _showApiKeyDialog(BuildContext context, WidgetRef ref, SettingsService settings) async {
    final controller = TextEditingController(text: settings.llmApiKey ?? '');
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Google Gemini API key to enable cloud-based analysis.\n'
              'Get a key at ai.google.dev.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIza...',
                border: OutlineInputBorder(),
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
              ref.read(settingsServiceProvider).llmApiKey = null;
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
              ref.read(settingsServiceProvider).llmApiKey = key;
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
}
