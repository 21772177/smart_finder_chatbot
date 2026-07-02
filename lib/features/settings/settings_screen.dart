import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_service.dart';
import 'blocked_apps_screen.dart';

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
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Delete All Data', style: TextStyle(color: theme.colorScheme.error)),
                  subtitle: const Text('Permanently erase all memories'),
                  onTap: () {},
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
}
