import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screen_capture_service.dart';
import 'ocr_service.dart';

final screenCaptureServiceProvider = Provider<ScreenCaptureService>((ref) => ScreenCaptureService());

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());
