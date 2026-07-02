import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../capture/ocr_service.dart';
import '../capture/screen_capture_service.dart';
import '../capture/capture_notifier.dart';
import '../memory/memory_repository.dart';
import '../analyze/analysis_service.dart';
import '../analyze/cloud_analysis_service.dart';
import '../analyze/local_llm_service.dart';
import '../settings/settings_service.dart';
import 'overlay_service.dart';

enum OverlayStatus { inactive, active, permissionDenied, unsupported }

class OverlayState {
  final OverlayStatus status;
  final bool accessibilityEnabled;
  final String? lastCaptureText;
  final String? lastCaptureError;
  final bool isCapturing;
  final String? summary;
  final List<String> keywords;
  final String? currentAppPackage;
  final String? blockedAppName;
  final String? analysisMode;
  final String? targetLanguage;

  const OverlayState({
    this.status = OverlayStatus.inactive,
    this.accessibilityEnabled = false,
    this.lastCaptureText,
    this.lastCaptureError,
    this.isCapturing = false,
    this.summary,
    this.keywords = const [],
    this.currentAppPackage,
    this.blockedAppName,
    this.analysisMode,
    this.targetLanguage,
  });

  OverlayState copyWith({
    OverlayStatus? status,
    bool? accessibilityEnabled,
    String? lastCaptureText,
    String? lastCaptureError,
    bool? isCapturing,
    String? summary,
    List<String>? keywords,
    String? currentAppPackage,
    String? blockedAppName,
    String? analysisMode,
    String? targetLanguage,
    bool clearBlocked = false,
    bool clearAnalysisMode = false,
  }) {
    return OverlayState(
      status: status ?? this.status,
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      lastCaptureText: lastCaptureText ?? this.lastCaptureText,
      lastCaptureError: lastCaptureError ?? this.lastCaptureError,
      isCapturing: isCapturing ?? this.isCapturing,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      currentAppPackage: currentAppPackage ?? this.currentAppPackage,
      blockedAppName: clearBlocked ? null : (blockedAppName ?? this.blockedAppName),
      analysisMode: clearAnalysisMode ? null : (analysisMode ?? this.analysisMode),
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }
}

class OverlayNotifier extends StateNotifier<OverlayState> {
  final OverlayService _service;
  final ScreenCaptureService _captureService;
  final OcrService _ocrService;
  final MemoryRepository _repository;
  final AnalysisService _analysisService;
  final CloudAnalysisService _cloudAnalysis;
  final LocalLLMService _localLLM;
  final SettingsService _settings;

  OverlayNotifier(
    this._service,
    this._captureService,
    this._ocrService,
    this._repository,
    this._analysisService,
    this._cloudAnalysis,
    this._localLLM,
    this._settings,
  ) : super(const OverlayState()) {
    _service.onTap = _onOverlayTap;
    _service.onSaveCapture = _onSaveCapture;
    _service.onDismissCapture = _onDismissCapture;
    _service.onAppChanged = _onAppChanged;
    _service.init();
  }

  void _onAppChanged(String package) {
    final blocked = _settings.blockedApps;
    final isBlocked = blocked.contains(package);
    state = state.copyWith(
      currentAppPackage: package,
      blockedAppName: isBlocked ? _findAppName(package) : null,
    );
  }

  String? _findAppName(String package) {
    for (final pkg in _settings.blockedApps) {
      final parts = pkg.split(':');
      if (parts.length == 2 && parts[0] == package) return parts[1];
      if (pkg == package) return package;
    }
    return package;
  }

  void _onOverlayTap() {
    if (state.blockedAppName != null) return;
    captureAndAnalyze();
  }

  void _onSaveCapture() {
    saveLastCapture();
  }

  void _onDismissCapture() {
    state = state.copyWith(lastCaptureText: null, lastCaptureError: null, summary: null, keywords: []);
  }

  Future<void> captureAndAnalyze({String? overrideText}) async {
    if (state.isCapturing) return;

    final currentPkg = state.currentAppPackage;
    if (currentPkg != null && _settings.blockedApps.contains(currentPkg)) {
      state = state.copyWith(
        isCapturing: false,
        lastCaptureError: 'Cannot capture: app is blocked',
      );
      return;
    }

    state = state.copyWith(isCapturing: true, lastCaptureError: null, lastCaptureText: null, summary: null, keywords: []);

    String text;
    if (overrideText != null) {
      text = overrideText;
    } else {
      final captureResult = await _captureService.captureCurrentScreen();
      if (!captureResult.isSuccess) {
        state = state.copyWith(isCapturing: false, lastCaptureError: captureResult.error);
        return;
      }
      final ocrResult = await _ocrService.extractText(captureResult.imagePath!);
      text = ocrResult.text;
    }

    final useCloud = _settings.enableCloudLLM && _cloudAnalysis.isConfigured;
    final useLocal = _settings.enableLocalLLM && _localLLM.isReady;

    AnalysisResult analysis;
    if (useCloud) {
      analysis = await _cloudAnalysis.analyze(text, mode: state.analysisMode, targetLanguage: state.targetLanguage);
    } else if (useLocal) {
      final llmResult = await _localLLM.analyze(text, mode: state.analysisMode);
      analysis = llmResult != null
          ? AnalysisResult(
              summary: llmResult,
              keywords: _analysisService.analyze(text).keywords,
              wordCount: text.split(RegExp(r'\s+')).length,
              sentenceCount: text.split(RegExp(r'[.!?\n]+')).where((s) => s.trim().isNotEmpty).length,
            )
          : _analysisService.analyze(text);
    } else {
      analysis = _analysisService.analyze(text);
    }

    state = state.copyWith(
      isCapturing: false,
      lastCaptureText: text,
      summary: analysis.summary,
      keywords: analysis.keywords,
    );

    if (text.isNotEmpty) {
      final modeLabel = switch (state.analysisMode) {
        'explain' => 'Explanation',
        'translate' => 'Translation (${state.targetLanguage ?? "English"})',
        _ => 'Summary',
      };
      final displayText = '[$modeLabel]\n${analysis.keywords.take(5).join(", ")}\n\n${analysis.summary}';
      _service.showResult(displayText);
    }
  }

  void setAnalysisMode(String? mode) {
    state = state.copyWith(analysisMode: mode);
  }

  void setTargetLanguage(String? lang) {
    state = state.copyWith(targetLanguage: lang);
  }

  void dismissLastCapture() {
    state = state.copyWith(lastCaptureText: null, lastCaptureError: null, summary: null, keywords: []);
  }

  Future<void> saveLastCapture({List<String>? tags}) async {
    final text = state.lastCaptureText;
    if (text == null || text.isEmpty) return;

    await _repository.saveMemoryEntry(
      title: 'Captured ${DateTime.now().toString().substring(0, 19)}',
      content: text,
      ocrText: text,
      tags: tags ?? ['capture', ...state.keywords.take(3)],
    );
    state = state.copyWith(lastCaptureText: null, summary: null, keywords: []);
  }

  Future<void> checkAccessibility() async {
    final enabled = await _service.isAccessibilityEnabled();
    state = state.copyWith(accessibilityEnabled: enabled);
  }

  Future<void> toggleOverlay() async {
    if (state.status == OverlayStatus.active) {
      final stopped = await _service.stopOverlay();
      if (stopped) state = state.copyWith(status: OverlayStatus.inactive);
    } else {
      final started = await _service.startOverlay();
      if (started) {
        state = state.copyWith(status: OverlayStatus.active);
        final pkg = await _service.getCurrentApp();
        if (pkg != null) _onAppChanged(pkg);
      } else {
        state = state.copyWith(status: OverlayStatus.permissionDenied);
      }
    }
  }

  Future<void> requestPermission() async {
    final result = await _service.requestAccessibilityPermission();
    if (result) {
      state = state.copyWith(accessibilityEnabled: true, status: OverlayStatus.inactive);
    }
  }

  void refreshBlockedState() {
    final pkg = state.currentAppPackage;
    if (pkg != null) _onAppChanged(pkg);
  }

  @override
  void dispose() {
    _service.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}

final overlayServiceProvider = Provider<OverlayService>((ref) => OverlayService());

final analysisServiceProvider = Provider<AnalysisService>((ref) => AnalysisService());

final overlayStateProvider = StateNotifierProvider<OverlayNotifier, OverlayState>((ref) {
  return OverlayNotifier(
    ref.watch(overlayServiceProvider),
    ref.watch(screenCaptureServiceProvider),
    ref.watch(ocrServiceProvider),
    ref.watch(memoryRepositoryProvider),
    ref.watch(analysisServiceProvider),
    ref.watch(cloudAnalysisServiceProvider),
    ref.watch(localLlmServiceProvider),
    ref.watch(settingsServiceProvider),
  );
});
