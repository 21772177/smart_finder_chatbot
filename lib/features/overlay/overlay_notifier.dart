import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../capture/ocr_service.dart';
import '../capture/screen_capture_service.dart';
import '../capture/capture_notifier.dart';
import '../memory/memory_repository.dart';
import '../analyze/analysis_service.dart';
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

  const OverlayState({
    this.status = OverlayStatus.inactive,
    this.accessibilityEnabled = false,
    this.lastCaptureText,
    this.lastCaptureError,
    this.isCapturing = false,
    this.summary,
    this.keywords = const [],
  });

  OverlayState copyWith({
    OverlayStatus? status,
    bool? accessibilityEnabled,
    String? lastCaptureText,
    String? lastCaptureError,
    bool? isCapturing,
    String? summary,
    List<String>? keywords,
  }) {
    return OverlayState(
      status: status ?? this.status,
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      lastCaptureText: lastCaptureText ?? this.lastCaptureText,
      lastCaptureError: lastCaptureError ?? this.lastCaptureError,
      isCapturing: isCapturing ?? this.isCapturing,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
    );
  }
}

class OverlayNotifier extends StateNotifier<OverlayState> {
  final OverlayService _service;
  final ScreenCaptureService _captureService;
  final OcrService _ocrService;
  final MemoryRepository _repository;
  final AnalysisService _analysisService;

  OverlayNotifier(this._service, this._captureService, this._ocrService, this._repository, this._analysisService)
      : super(const OverlayState()) {
    _service.onTap = _onOverlayTap;
    _service.onSaveCapture = _onSaveCapture;
    _service.onDismissCapture = _onDismissCapture;
    _service.init();
  }

  void _onOverlayTap() {
    captureAndAnalyze();
  }

  void _onSaveCapture() {
    saveLastCapture();
  }

  void _onDismissCapture() {
    state = state.copyWith(lastCaptureText: null, lastCaptureError: null, summary: null, keywords: []);
  }

  Future<void> captureAndAnalyze() async {
    if (state.isCapturing) return;
    state = state.copyWith(isCapturing: true, lastCaptureError: null, lastCaptureText: null, summary: null, keywords: []);

    final captureResult = await _captureService.captureCurrentScreen();
    if (!captureResult.isSuccess) {
      state = state.copyWith(isCapturing: false, lastCaptureError: captureResult.error);
      return;
    }

    final ocrResult = await _ocrService.extractText(captureResult.imagePath!);
    final text = ocrResult.text;
    final analysis = _analysisService.analyze(text);

    state = state.copyWith(
      isCapturing: false,
      lastCaptureText: text,
      summary: analysis.summary,
      keywords: analysis.keywords,
    );

    if (text.isNotEmpty) {
      final displayText = '${analysis.keywords.take(5).join(", ")}\n\n${analysis.summary}';
      _service.showResult(displayText);
    }
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
  );
});
