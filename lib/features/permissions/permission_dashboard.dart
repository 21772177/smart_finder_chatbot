import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permission_service.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) => PermissionService());

final permissionStatusProvider = FutureProvider.autoDispose<Map<String, bool>>((ref) {
  return ref.watch(permissionServiceProvider).checkAll();
});

class PermissionDashboard extends ConsumerWidget {
  const PermissionDashboard({super.key});

  static const _permissions = [
    _PermDef('overlay', 'Display Overlay', 'Show floating bubble on other apps', Icons.picture_in_picture),
    _PermDef('accessibility', 'Accessibility Service', 'Read screen content and track current app', Icons.accessibility),
    _PermDef('notifications', 'Notifications', 'Show persistent service notification', Icons.notifications),
    _PermDef('audio', 'Microphone', 'Record audio for on-device transcription', Icons.mic),
    _PermDef('media_projection', 'Screen Capture', 'Capture screen content for OCR analysis', Icons.screenshot),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permAsync = ref.watch(permissionStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(permissionStatusProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Second Brain requires these permissions to function. '
              'Each can be revoked at any time.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...permAsync.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (e, _) => [Center(child: Text('Error: $e'))],
              data: (perms) => _permissions.map((p) {
                final granted = perms[p.key] ?? false;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      p.icon,
                      color: granted ? Colors.green : theme.colorScheme.error,
                    ),
                    title: Text(p.label),
                    subtitle: Text(p.description),
                    trailing: granted
                        ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                        : FilledButton.tonal(
                            onPressed: () => _openSettings(ref, p.key),
                            child: const Text('Grant'),
                          ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.invalidate(permissionStatusProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings(WidgetRef ref, String key) async {
    final service = ref.read(permissionServiceProvider);
    switch (key) {
      case 'overlay':
        await service.openOverlaySettings();
      case 'accessibility':
        await service.openAccessibilitySettings();
      case 'notifications':
        await service.openNotificationSettings();
      case 'audio':
        await service.openAppSettings();
      case 'media_projection':
        await service.openAppSettings();
    }
    ref.invalidate(permissionStatusProvider);
  }
}

class _PermDef {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const _PermDef(this.key, this.label, this.description, this.icon);
}
