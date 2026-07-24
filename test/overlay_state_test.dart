import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/overlay/overlay_notifier.dart';

void main() {
  group('OverlayState', () {
    test('default state', () {
      const state = OverlayState();

      expect(state.status, OverlayStatus.inactive);
      expect(state.accessibilityEnabled, isFalse);
      expect(state.lastCaptureText, isNull);
      expect(state.lastCaptureError, isNull);
      expect(state.isCapturing, isFalse);
      expect(state.summary, isNull);
      expect(state.keywords, isEmpty);
      expect(state.currentAppPackage, isNull);
      expect(state.blockedAppName, isNull);
      expect(state.analysisMode, isNull);
      expect(state.targetLanguage, isNull);
    });

    test('copyWith preserves existing values', () {
      const original = OverlayState(
        status: OverlayStatus.active,
        lastCaptureText: 'captured text',
        summary: 'a summary',
        keywords: ['kw1', 'kw2'],
        analysisMode: 'explain',
        targetLanguage: 'French',
      );

      final copy = original.copyWith(isCapturing: true);

      expect(copy.status, OverlayStatus.active);
      expect(copy.lastCaptureText, 'captured text');
      expect(copy.summary, 'a summary');
      expect(copy.keywords, ['kw1', 'kw2']);
      expect(copy.isCapturing, isTrue);
      expect(copy.analysisMode, 'explain');
      expect(copy.targetLanguage, 'French');
    });

    test('copyWith overrides specified fields', () {
      const original = OverlayState(
        status: OverlayStatus.active,
        summary: 'old summary',
      );

      final copy = original.copyWith(
        status: OverlayStatus.permissionDenied,
        summary: 'new summary',
      );

      expect(copy.status, OverlayStatus.permissionDenied);
      expect(copy.summary, 'new summary');
    });

    test('copyWith clearBlocked removes blockedAppName', () {
      const original = OverlayState(blockedAppName: 'com.bank.app');

      final cleared = original.copyWith(clearBlocked: true);
      expect(cleared.blockedAppName, isNull);

      final notCleared = original.copyWith(clearBlocked: false, blockedAppName: 'other');
      expect(notCleared.blockedAppName, 'other');
    });

    test('copyWith clearAnalysisMode removes analysisMode', () {
      const original = OverlayState(analysisMode: 'translate');

      final cleared = original.copyWith(clearAnalysisMode: true);
      expect(cleared.analysisMode, isNull);
    });

    test('copyWith preserves keywords list', () {
      const original = OverlayState(keywords: ['a', 'b', 'c']);
      final copy = original.copyWith(status: OverlayStatus.active);

      expect(copy.keywords, ['a', 'b', 'c']);
    });

    test('copyWith clearError removes lastCaptureError', () {
      const original = OverlayState(lastCaptureError: 'Something went wrong');

      final cleared = original.copyWith(clearError: true);
      expect(cleared.lastCaptureError, isNull);

      // Without clearError, the old error persists
      final notCleared = original.copyWith(clearError: false);
      expect(notCleared.lastCaptureError, 'Something went wrong');
    });

    test('copyWith clearError does not affect other fields', () {
      const original = OverlayState(
        lastCaptureText: 'text',
        lastCaptureError: 'error',
        summary: 'summary',
        keywords: ['kw'],
      );

      final cleared = original.copyWith(clearError: true);
      expect(cleared.lastCaptureError, isNull);
      expect(cleared.lastCaptureText, 'text');
      expect(cleared.summary, 'summary');
      expect(cleared.keywords, ['kw']);
    });

    test('copyWith clearCapture removes text, summary, keywords', () {
      const original = OverlayState(
        lastCaptureText: 'captured text',
        lastCaptureError: 'error',
        summary: 'a summary',
        keywords: ['kw1', 'kw2'],
      );

      final cleared = original.copyWith(clearCapture: true);
      expect(cleared.lastCaptureText, isNull);
      expect(cleared.summary, isNull);
      expect(cleared.keywords, isEmpty);
      // clearCapture should NOT clear the error
      expect(cleared.lastCaptureError, 'error');
    });

    test('copyWith clearCapture and clearError together', () {
      const original = OverlayState(
        lastCaptureText: 'text',
        lastCaptureError: 'error',
        summary: 'summary',
        keywords: ['kw'],
      );

      final cleared = original.copyWith(clearCapture: true, clearError: true);
      expect(cleared.lastCaptureText, isNull);
      expect(cleared.lastCaptureError, isNull);
      expect(cleared.summary, isNull);
      expect(cleared.keywords, isEmpty);
    });

    test('copyWith clearCapture with explicit values overrides clear', () {
      const original = OverlayState(
        lastCaptureText: 'old',
        summary: 'old summary',
        keywords: ['old'],
      );

      final result = original.copyWith(
        clearCapture: true,
        lastCaptureText: 'new',
        summary: 'new summary',
        keywords: ['new'],
      );
      // clearCapture runs first, then explicit values override
      expect(result.lastCaptureText, 'new');
      expect(result.summary, 'new summary');
      expect(result.keywords, ['new']);
    });
  });
}
