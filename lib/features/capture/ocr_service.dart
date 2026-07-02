import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String text;
  final List<String> lines;
  final double confidence;

  const OcrResult({
    required this.text,
    required this.lines,
    this.confidence = 0.0,
  });
}

class OcrService {
  final TextRecognizer _recognizer;

  OcrService() : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> extractText(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return const OcrResult(text: '', lines: [], confidence: 0.0);
    }

    final inputImage = InputImage.fromFile(file);
    final recognisedText = await _recognizer.processImage(inputImage);

    final lines = <String>[];
    for (final block in recognisedText.blocks) {
      for (final line in block.lines) {
        if (line.text.trim().isNotEmpty) {
          lines.add(line.text.trim());
        }
      }
    }

    return OcrResult(
      text: lines.join('\n'),
      lines: lines,
    );
  }

  void dispose() {
    _recognizer.close();
  }
}
