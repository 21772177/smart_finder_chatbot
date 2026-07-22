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
  });
}
