import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'settings_service.dart';

class BlockedAppsScreen extends ConsumerStatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  ConsumerState<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends ConsumerState<BlockedAppsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);
    final blocked = settings.blockedApps;
    final theme = Theme.of(context);

    final grouped = _buildGroupedList(blocked);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(blocked),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (blocked.isEmpty && _searchQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.security, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('No apps blocked', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Banking, payment & password apps\nare blocked from capture when detected',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...grouped.entries.map((entry) => _buildSection(theme, entry, blocked)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<MapEntry<String, String>>> _buildGroupedList(List<String> blocked) {
    final allApps = <String, String>{};

    for (final pkg in AppConstants.blockedApps) {
      allApps.putIfAbsent(pkg, () => _friendlyName(pkg));
    }

    for (final pkg in blocked) {
      allApps.putIfAbsent(pkg, () => _friendlyName(pkg));
    }

    final filtered = allApps.entries.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.key.toLowerCase().contains(_searchQuery) ||
          e.value.toLowerCase().contains(_searchQuery);
    }).toList()
      ..sort((a, b) {
        final aBlocked = blocked.contains(a.key);
        final bBlocked = blocked.contains(b.key);
        if (aBlocked && !bBlocked) return -1;
        if (!aBlocked && bBlocked) return 1;
        return a.value.compareTo(b.value);
      });

    final Map<String, List<MapEntry<String, String>>> groups = {};
    for (final entry in filtered) {
      final isBlocked = blocked.contains(entry.key);
      final group = isBlocked ? 'Blocked' : 'Not Blocked';
      groups.putIfAbsent(group, () => []);
      groups[group]!.add(entry);
    }

    return groups;
  }

  Widget _buildSection(ThemeData theme, MapEntry<String, List<MapEntry<String, String>>> entry, List<String> blocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.value.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entry.key,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: entry.value.map((app) =>
                  _buildAppTile(app.key, app.value, blocked)).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildAppTile(String package, String name, List<String> blocked) {
    final isBlocked = blocked.contains(package);
    return ListTile(
      leading: Icon(
        isBlocked ? Icons.block : Icons.check_circle_outline,
        color: isBlocked ? Colors.red : Colors.green,
      ),
      title: Text(name),
      subtitle: Text(package, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: isBlocked,
        onChanged: (v) {
          final updated = List<String>.from(blocked);
          if (v) {
            updated.add(package);
          } else {
            updated.remove(package);
          }
          ref.read(settingsServiceProvider).blockedApps = updated;
          ref.invalidate(settingsServiceProvider);
        },
      ),
    );
  }

  String _friendlyName(String package) {
    final segments = package.split('.');
    final last = segments.last;
    return last[0].toUpperCase() + last.substring(1);
  }

  void _showAddDialog(List<String> blocked) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add App to Block'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Package name',
            hintText: 'com.example.app',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pkg = controller.text.trim();
              if (pkg.isNotEmpty && !blocked.contains(pkg)) {
                final updated = List<String>.from(blocked)..add(pkg);
                ref.read(settingsServiceProvider).blockedApps = updated;
                ref.invalidate(settingsServiceProvider);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}
