import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/book_recognition_service.dart';

// Diagnostic dump for recognition tuning (#78): everything needed to rebuild a
// photo's OCR as a test fixture, plus the query it produced. Debug builds only.
// One short record per line so logcat never truncates mid-record.
// A genuine miss and a request that never completed both reach searchBooks as
// null. Open Library stalls under burst load, so telling them apart is the
// difference between "recognition failed" and "the network did".
void logLookupFailure(String query, String reason) {
  if (!kDebugMode) return;
  debugPrint('[REC] miss | $reason | $query');
}

void logRecognition({
  required String imagePath,
  required OcrResult ocr,
  required String query,
  required List<Book> books,
  required double confidence,
}) {
  if (!kDebugMode) return;

  debugPrint('[REC] file | ${imagePath.split(RegExp(r'[/\\]')).last}');
  debugPrint('[REC] meta | screenshot=${ocr.isScreenshot}'
      ' | height=${ocr.imageHeight} | lines=${ocr.lines.length}');
  for (final line in ocr.lines) {
    final box = line.boundingBox;
    debugPrint('[REC] line | ${box.left.round()},${box.top.round()},'
        '${box.right.round()},${box.bottom.round()} | ${line.text}');
  }
  debugPrint('[REC] query | $query');
  final top = books.isEmpty ? null : books.first;
  debugPrint('[REC] top | ${top?.title ?? '(none)'} | ${top?.author ?? '-'}'
      ' | conf=${confidence.toStringAsFixed(2)}');
  // One per entry behind "See other matches" on the review card, so a
  // duplicate-edition list is visible in the log and not only on screen.
  for (final other in books.skip(1)) {
    debugPrint('[REC] also | ${other.title} | ${other.author ?? '-'}');
  }
  debugPrint('[REC] end');
}
