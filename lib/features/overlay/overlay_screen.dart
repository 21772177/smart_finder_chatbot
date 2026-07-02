import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../capture/capture_notifier.dart';
import '../memory/memory_repository.dart';
import 'overlay_notifier.dart';

class OverlayScreen extends ConsumerWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(overlayStateProvider);
    final captureState = ref.watch(captureStateProvider);
    final notifier = ref.read(overlayStateProvider.notifier);
    final captureNotifier = ref.read(captureStateProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Brain'),
        centerTitle: true,
      ),
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
                    subtitle: Text(
                      overlayState.accessibilityEnabled ? 'Granted' : 'Required for overlay',
                    ),
                    value: overlayState.accessibilityEnabled,
                    onChanged: (_) => notifier.requestPermission(),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Floating Overlay'),
                    subtitle: Text(
                      overlayState.status == OverlayStatus.active
                          ? 'Tap the bubble to analyze screen'
                          : 'Start to enable overlay',
                    ),
                    value: overlayState.status == OverlayStatus.active,
                    onChanged: overlayState.accessibilityEnabled
                        ? (_) => notifier.toggleOverlay()
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (overlayState.status == OverlayStatus.permissionDenied)
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
                        child: Text(
                          'Permission denied. Enable Accessibility Service in Settings.',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
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
                  Text('Manual Capture', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Test screen capture and OCR', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: captureState.phase == CapturePhase.capturing ||
                             captureState.phase == CapturePhase.processing
                        ? null
                        : () => captureNotifier.captureAndAnalyze(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture & Analyze'),
                  ),
                ],
              ),
            ),
          ),
          if (captureState.phase == CapturePhase.capturing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: LinearProgressIndicator(),
            ),
          if (captureState.phase == CapturePhase.processing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Processing with AI...'),
                ],
              ),
            ),
          if (captureState.phase == CapturePhase.done) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OCR Result', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        captureState.ocrText?.isNotEmpty == true
                            ? captureState.ocrText!
                            : 'No text detected',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final repo = ref.read(memoryRepositoryProvider);
                        await repo.saveMemoryEntry(
                          title: 'Screen ${DateTime.now().toString().substring(0, 19)}',
                          content: captureState.ocrText ?? '',
                          ocrText: captureState.ocrText,
                          tags: ['capture'],
                        );
                        captureNotifier.reset();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved to memory!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save to Memory'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (captureState.phase == CapturePhase.error)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${captureState.error}',
                    style: TextStyle(color: colorScheme.onErrorContainer)),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Privacy First', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
