import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrLine {
  final String text;
  final ui.Rect boundingBox;

  const OcrLine(this.text, this.boundingBox);
}

class OcrResult {
  final List<OcrLine> lines;
  final int imageHeight;
  final bool isScreenshot;

  const OcrResult({
    required this.lines,
    required this.imageHeight,
    required this.isScreenshot,
  });

  String get rawText => lines.map((l) => l.text).join('\n');
}

class BookRecognitionService {
  Future<OcrResult> extractTextFromImage(XFile image) async {
    final recognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await recognizer.processImage(inputImage);

      final lines = [
        for (final block in recognizedText.blocks)
          for (final line in block.lines)
            OcrLine(line.text, line.boundingBox),
      ];

      final (width, height) = await _imageDimensions(image);

      return OcrResult(
        lines: lines,
        imageHeight: height,
        isScreenshot: _isScreenshot(width, height),
      );
    } finally {
      await recognizer.close();
    }
  }

  Future<(int width, int height)> _imageDimensions(XFile image) async {
    final bytes = await image.readAsBytes();
    // Read only the image header for dimensions — no full-pixel decode (which
    // would stall the UI thread on large photos and stutter the loading spinner).
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final dimensions = (descriptor.width, descriptor.height);
    descriptor.dispose();
    buffer.dispose();
    return dimensions;
  }

  // Portrait aspect ratio taller than 16:9 (1.78) — modern phone screens are
  // 19.5:9 (~2.16) or 20:9 (~2.22); camera photos are 4:3 or 16:9 and stay below.
  bool _isScreenshot(int width, int height) {
    if (width == 0 || height <= width) return false;
    return height / width >= 1.85;
  }
}
