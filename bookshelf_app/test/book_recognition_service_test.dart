import 'dart:ui';

import 'package:bookshelf_app/services/book_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/ocr_fixtures.dart';

// Tests for the transposition gate (#94, #105). These exercise the gate itself,
// which nothing did before: `ocr_fixtures.dart` holds the *output* of this
// service, and every other test feeds it straight into the query builder. That
// gap is how #105 survived, so this file deliberately calls the decision
// directly rather than going through extractTextFromImage (which needs ML Kit
// and a real photo).
void main() {
  final service = BookRecognitionService();

  // iOS reports frames in the photo's unrotated buffer, so every box arrives
  // with its axes swapped. The fixtures hold correct Android geometry, so
  // swapping them simulates what iOS hands us.
  List<OcrLine> swapAxes(List<OcrLine> lines) => [
        for (final line in lines)
          OcrLine(
            line.text,
            Rect.fromLTRB(
              line.boundingBox.top,
              line.boundingBox.left,
              line.boundingBox.bottom,
              line.boundingBox.right,
            ),
          ),
      ];

  List<OcrLine> linesOf(String name) =>
      ocrFixtures.firstWhere((f) => f.name == name).ocr.lines;

  group('Android is never transposed (#105)', () {
    test('no real photo is touched, whatever its text geometry', () {
      for (final fixture in ocrFixtures) {
        expect(service.shouldTranspose(fixture.ocr.lines, isIOS: false), isFalse,
            reason: '${fixture.name} was transposed on Android');
      }
    });

    test('not even the shelf photo that used to trip the heuristic', () {
      // Invisible Cities carries five neighbouring spines against three lines
      // of cover text. The vote inside _hasTransposedBoxes still goes the wrong
      // way — the platform gate is what makes that harmless.
      final shelf = linesOf('scaled_1458.heic');
      expect(service.shouldTranspose(shelf, isIOS: false), isFalse);
      expect(service.shouldTranspose(shelf, isIOS: true), isTrue,
          reason: 'the underlying heuristic is still wrong here (#107); this '
              'test documents that rather than accepting it');
    });
  });

  group('the iOS gate still catches genuinely swapped boxes', () {
    test('fires on axis-swapped copies of real covers', () {
      final fired = ocrFixtures
          .where((f) => service.shouldTranspose(swapAxes(f.ocr.lines), isIOS: true))
          .length;
      // Not all 20: a photo whose lines are mostly short falls below the sample
      // floor, and one already votes the wrong way (the shelf photo above).
      expect(fired, greaterThan(ocrFixtures.length ~/ 2),
          reason: 'the iOS path must still correct transposed frames');
    });

    test('a clean cover flips in both directions', () {
      // Authority: four lines of horizontal cover text, no spines.
      final clean = linesOf('scaled_1500.heic');
      expect(service.shouldTranspose(clean, isIOS: true), isFalse);
      expect(service.shouldTranspose(swapAxes(clean), isIOS: true), isTrue);
    });
  });
}
