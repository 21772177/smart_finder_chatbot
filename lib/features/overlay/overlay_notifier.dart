import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'overlay_service.dart';

enum OverlayStatus { inactive, active, permissionDenied, unsupported }

class OverlayState {
  final OverlayStatus status;
  final bool accessibilityEnabled;

  const OverlayState({
    this.status = OverlayStatus.inactive,
    this.accessibilityEnabled = false,
  });

  OverlayState copyWith({OverlayStatus? status, bool? accessibilityEnabled}) {
    return OverlayState(
      status: status ?? this.status,
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
    );
  }
}

class OverlayNotifier extends StateNotifier<OverlayState> {
  final OverlayService _service;

  OverlayNotifier(this._service) : super(const OverlayState());

  Future<void> checkAccessibility() async {
    final enabled = await _service.isAccessibilityEnabled();
    state = state.copyWith(accessibilityEnabled: enabled);
  }

  Future<void> toggleOverlay() async {
    if (state.status == OverlayStatus.active) {
      final stopped = await _service.stopOverlay();
      if (stopped) {
        state = state.copyWith(status: OverlayStatus.inactive);
      }
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
}

final overlayServiceProvider = Provider<OverlayService>((ref) => OverlayService());

final overlayStateProvider = StateNotifierProvider<OverlayNotifier, OverlayState>((ref) {
  return OverlayNotifier(ref.watch(overlayServiceProvider));
});
