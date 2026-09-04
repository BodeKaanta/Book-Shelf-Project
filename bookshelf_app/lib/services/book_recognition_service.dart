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
          for (final line in block.lines) OcrLine(line.text, line.boundingBox),
      ];

      final (width, height) = await _imageDimensions(image);
      final transposed = _hasTransposedBoxes(lines);

      return OcrResult(
        lines: transposed ? _transposeBoxes(lines) : lines,
        imageHeight: transposed ? width : height,
        isScreenshot: _isScreenshot(width, height),
      );
    } finally {
      await recognizer.close();
    }
  }

  // ML Kit on iOS returns frames in the photo's unrotated buffer, so an
  // EXIF-rotated photo arrives with every box's axes swapped -- a 37-character
  // line of cover text measuring 69 wide by 458 tall. The query builder reads a
  // box taller than it is wide as a neighbouring book's spine and drops it, so
  // almost every line of a rotated cover was being discarded and the query built
  // from scraps ("THE", "A", "sci"). Correcting at this boundary keeps every
  // rule downstream working on the geometry it was tuned for.
  //
  // Line length is the signal: horizontal text of four or more characters is
  // always wider than it is tall, so six is a safe floor, while a short line
  // ("JN", "A") legitimately is not. Six caught every rotated photo in the
  // 20-photo set with no false positives; twelve missed two sparse covers.
  static const _aspectSampleMinLength = 6;
  static const _aspectSampleMinCount = 3;

  bool _hasTransposedBoxes(List<OcrLine> lines) {
    final sample = [
      for (final line in lines)
        if (line.text.length >= _aspectSampleMinLength) line.boundingBox,
    ];
    if (sample.length < _aspectSampleMinCount) return false;
    final tall = sample.where((box) => box.height > box.width).length;
    return tall * 2 > sample.length;
  }

  List<OcrLine> _transposeBoxes(List<OcrLine> lines) => [
    for (final line in lines)
      OcrLine(
        line.text,
        ui.Rect.fromLTRB(
          line.boundingBox.top,
          line.boundingBox.left,
          line.boundingBox.bottom,
          line.boundingBox.right,
        ),
      ),
  ];

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
