import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'overlay_notifier.dart';

class OverlayScreen extends ConsumerWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(overlayStateProvider);
    final notifier = ref.read(overlayStateProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Second Brain'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.psychology, size: 80, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Your Private AI Assistant',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the floating bubble to analyze any screen.\nNothing is collected without your permission.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Accessibility Service'),
                    subtitle: Text(state.accessibilityEnabled ? 'Granted' : 'Required for overlay'),
                    value: state.accessibilityEnabled,
                    onChanged: (_) => notifier.requestPermission(),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Floating Overlay'),
                    subtitle: Text(
                      state.status == OverlayStatus.active
                          ? 'Tap the bubble to analyze screen'
                          : 'Start to enable overlay',
                    ),
                    value: state.status == OverlayStatus.active,
                    onChanged: state.accessibilityEnabled ? (_) => notifier.toggleOverlay() : null,
                  ),
                ],
              ),
            ),
          ),
          if (state.status == OverlayStatus.permissionDenied)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Permission denied. Enable Accessibility Service in Settings.',
                            style: TextStyle(color: colorScheme.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manual Capture Test', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Simulates what happens when the overlay is tapped.',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: state.isCapturing ? null : () => notifier.captureAndAnalyze(),
                    icon: state.isCapturing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.camera_alt),
                    label: Text(state.isCapturing ? 'Analyzing...' : 'Capture & Analyze'),
                  ),
                ],
              ),
            ),
          ),
          if (state.isCapturing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
            ),
          if (state.lastCaptureError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${state.lastCaptureError}',
                      style: TextStyle(color: colorScheme.onErrorContainer)),
                ),
              ),
            ),
          if (!state.isCapturing && state.lastCaptureText != null && state.lastCaptureText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Analysis', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      if (state.keywords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: state.keywords.take(10).map((kw) =>
                            Chip(
                              label: Text(kw, style: const TextStyle(fontSize: 12)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ).toList(),
                        ),
                      ],
                      if (state.summary != null && state.summary!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Summary', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(state.summary!, style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 8),
                      Text('Raw Text', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          state.lastCaptureText!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () => notifier.saveLastCapture(),
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => notifier.dismissLastCapture(),
                            icon: const Icon(Icons.close),
                            label: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Privacy First',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _privacyFeature(theme, '100% on-device processing'),
          _privacyFeature(theme, 'No cloud storage by default'),
          _privacyFeature(theme, 'Encrypted local database'),
          _privacyFeature(theme, 'Banking & password apps blocked'),
          _privacyFeature(theme, 'Export or delete your data anytime'),
        ],
      ),
    );
  }

  Widget _privacyFeature(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
