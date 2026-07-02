import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screen_capture_service.dart';
import 'ocr_service.dart';

enum CapturePhase { idle, capturing, processing, done, error }

class CaptureState {
  final CapturePhase phase;
  final String? ocrText;
  final List<String> ocrLines;
  final String? error;
  final String? imagePath;

  const CaptureState({
    this.phase = CapturePhase.idle,
    this.ocrText,
    this.ocrLines = const [],
    this.error,
    this.imagePath,
  });

  CaptureState copyWith({
    CapturePhase? phase,
    String? ocrText,
    List<String>? ocrLines,
    String? error,
    String? imagePath,
  }) {
    return CaptureState(
      phase: phase ?? this.phase,
      ocrText: ocrText ?? this.ocrText,
      ocrLines: ocrLines ?? this.ocrLines,
      error: error ?? this.error,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final ScreenCaptureService _captureService;
  final OcrService _ocrService;

  CaptureNotifier(this._captureService, this._ocrService)
      : super(const CaptureState());

  Future<void> captureAndAnalyze() async {
    state = state.copyWith(phase: CapturePhase.capturing, error: null);

    final captureResult = await _captureService.captureCurrentScreen();
    if (!captureResult.isSuccess) {
      state = state.copyWith(
        phase: CapturePhase.error,
        error: captureResult.error,
      );
      return;
    }

    state = state.copyWith(
      phase: CapturePhase.processing,
      imagePath: captureResult.imagePath,
    );

    final ocrResult = await _ocrService.extractText(captureResult.imagePath!);

    state = state.copyWith(
      phase: CapturePhase.done,
      ocrText: ocrResult.text,
      ocrLines: ocrResult.lines,
    );
  }

  void reset() {
    state = const CaptureState();
  }
}

final screenCaptureServiceProvider = Provider<ScreenCaptureService>((ref) => ScreenCaptureService());

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());

final captureStateProvider = StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier(
    ref.watch(screenCaptureServiceProvider),
    ref.watch(ocrServiceProvider),
  );
});
