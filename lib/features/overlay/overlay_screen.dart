import 'package:flutter/material.dart' hide OverlayState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../audio/audio_transcription_service.dart';
import '../chat/chat_notifier.dart';
import '../settings/settings_service.dart';
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
          // Hero section
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

          // Overlay controls
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

          // Permission denied warning
          if (state.status == OverlayStatus.permissionDenied)
            _buildWarningCard(colorScheme, Icons.warning, 'Permission denied. Enable Accessibility Service in Settings.'),

          // Cloud LLM not configured warning
          if (ref.watch(settingsServiceProvider).enableCloudLLM &&
              !ref.watch(settingsServiceProvider).geminiApiKey.isNullOrEmpty() &&
              ref.watch(settingsServiceProvider).openaiApiKey.isNullOrEmpty() &&
              ref.watch(settingsServiceProvider).anthropicApiKey.isNullOrEmpty())
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildWarningCard(
                colorScheme,
                Icons.cloud_off,
                'Cloud LLM enabled but no API key configured. Go to Settings to add a key.',
              ),
            ),

          const SizedBox(height: 16),

          // Manual capture section
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
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'summarize', label: Text('Summarize'), icon: Icon(Icons.summarize, size: 16)),
                      ButtonSegment(value: 'explain', label: Text('Explain'), icon: Icon(Icons.lightbulb, size: 16)),
                      ButtonSegment(value: 'translate', label: Text('Translate'), icon: Icon(Icons.translate, size: 16)),
                      ButtonSegment(value: 'takeaways', label: Text('Takeaways'), icon: Icon(Icons.checklist, size: 16)),
                    ],
                    selected: {state.analysisMode ?? 'summarize'},
                    onSelectionChanged: (selected) => notifier.setAnalysisMode(selected.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (state.analysisMode == 'translate') ...[
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Target Language',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.targetLanguage ?? 'English',
                          isExpanded: true,
                          isDense: true,
                          items: ['English', 'Hindi', 'Spanish', 'French', 'German', 'Japanese', 'Chinese', 'Arabic', 'Portuguese', 'Russian', 'Korean']
                              .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                          onChanged: (v) {
                            if (v != null) notifier.setTargetLanguage(v);
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: state.isCapturing ? null : () => notifier.captureAndAnalyze(),
                    icon: state.isCapturing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.camera_alt),
                    label: Text(state.isCapturing ? 'Analyzing...' : 'Capture & Analyze'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Audio transcription section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audio Transcription', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Transcribe speech from the current audio/video content.',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _startTranscription(context, ref, notifier, state),
                    icon: const Icon(Icons.mic),
                    label: const Text('Transcribe Audio'),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator during capture
          if (state.isCapturing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Capturing and analyzing screen...',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Error state
          if (state.lastCaptureError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Capture Failed',
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              state.lastCaptureError!,
                              style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: colorScheme.onErrorContainer),
                        onPressed: () => notifier.captureAndAnalyze(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Results display
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
                            ActionChip(
                              label: Text(kw, style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(Icons.search, size: 14),
                              onPressed: () => _searchByKeyword(context, ref, kw),
                            ),
                          ).toList(),
                        ),
                      ],
                      if (state.summary != null && state.summary!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_resultLabel(state.analysisMode, state.targetLanguage), style: theme.textTheme.titleSmall),
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
                            label: const Text('Save to Memory'),
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

  String _resultLabel(String? mode, String? targetLanguage) {
    return switch (mode) {
      'explain' => 'Explanation',
      'translate' => 'Translation (${targetLanguage ?? "English"})',
      'takeaways' => 'Key Takeaways',
      _ => 'Summary',
    };
  }

  void _searchByKeyword(BuildContext context, WidgetRef ref, String keyword) {
    // Switch to search tab and trigger search
    ref.read(selectedTabProvider.notifier).state = 1; // Search tab
    Future.microtask(() {
      ref.read(chatStateProvider.notifier).search(keyword);
    });
  }

  Future<void> _startTranscription(BuildContext context, WidgetRef ref, OverlayNotifier notifier, OverlayState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final audioService = ref.read(audioTranscriptionServiceProvider);

    final hasPerm = await audioService.checkPermission();
    if (!hasPerm) {
      final granted = await audioService.requestPermission();
      if (!granted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Microphone permission required for transcription')),
        );
        return;
      }
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Listening...'), duration: Duration(seconds: 1)),
    );

    final result = await audioService.startListening();

    if (result != null && result.isNotEmpty) {
      notifier.captureAndAnalyze(overrideText: result);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(audioService.lastError ?? 'No speech detected')),
      );
    }
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

  Widget _buildWarningCard(ColorScheme colorScheme, IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to check if a nullable string is null or empty
extension _NullableStringX on String? {
  bool isNullOrEmpty() => this == null || this!.isEmpty;
}
