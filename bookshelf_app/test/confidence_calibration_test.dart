import 'package:bookshelf_app/core/constants.dart';
import 'package:bookshelf_app/models/book.dart';
import 'package:bookshelf_app/services/books_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/candidate_fixtures.dart';
import 'fixtures/ocr_fixtures.dart';

// Offline calibration of the confidence score (#83). The candidates are real
// Google Books result lists for the queries the current builder produces from
// Margot's 20 photos, so this exercises the scorer on the data it actually
// sees — with no device and no network call.
void main() {
  final service = BooksApiService();

  ({List<Book> books, double confidence}) rank(String fixture) {
    final candidates =
        candidateFixtures.firstWhere((c) => c.name == fixture).candidates;
    final ocr = ocrFixtures.firstWhere((f) => f.name == fixture).ocr;
    return service.rankCandidates(candidates, ocr);
  }

  int distinctWorks(List<Book> books) =>
      books.map((b) => Book.identityKey(b.title, b.author)).nonNulls.toSet().length;

  group('duplicate editions are collapsed', () {
    test('no fixture keeps two records of the same book', () {
      for (final fixture in candidateFixtures) {
        final ranked = rank(fixture.name).books;
        final keyed =
            ranked.map((b) => Book.identityKey(b.title, b.author)).nonNulls;
        expect(keyed.length, distinctWorks(ranked),
            reason: '${fixture.name} offered the same book twice');
      }
    });

    test('The Overstory arrives several times and survives once', () {
      const name = 'scaled_1496.heic';
      final raw = candidateFixtures.firstWhere((c) => c.name == name).candidates;
      // The whole premise of #83: Google returns one book as several editions.
      expect(raw.length, greaterThan(distinctWorks(raw)));
      final ranked = rank(name).books;
      expect(ranked.length, distinctWorks(ranked));
      expect(ranked.first.title, 'The Overstory');
    });
  });

  group('correct matches are no longer capped at ~0.70', () {
    // Each of these had a duplicate edition as its runner-up, so the margin
    // term was 0 and confidence could not exceed 0.7 x topMatch.
    const freed = {
      'scaled_1454.jpg': 'Transformed',
      'scaled_1452.jpg': 'The Notebook',
      'scaled_1458.heic': 'Invisible Cities',
      'scaled_1459.heic': 'The Dream Hotel',
      'scaled_1496.heic': 'The Overstory',
    };

    freed.forEach((fixture, label) {
      test(label, () {
        final result = rank(fixture);
        expect(result.confidence, greaterThan(0.70),
            reason: '$label should clear the old duplicate-edition cap');
      });
    });
  });

  group('wrong matches must stay out of the library', () {
    // Pines and Monk & Robot are the trap: both scored low *because* of the
    // margin bug, so collapsing editions must not push them over the line.
    // Their runners-up are genuinely different books that also match the OCR,
    // which is what keeps them uncertain for the right reason.
    const wrong = {
      'scaled_1460.png': 'Pines matches Wayward, the next book in the series',
      'scaled_1498.heic': 'the Monk & Robot omnibus matches book 1 via a blurb',
      'scaled_1456.heic': 'a shelf photo holding four different books',
      'scaled_1497.heic': 'destroyed OCR (AVELL Cheerf Retuse)',
      'scaled_1499.heic': 'right title, wrong author',
    };

    wrong.forEach((fixture, why) {
      test(why, () {
        expect(rank(fixture).confidence, lessThan(autoAddConfidenceThreshold),
            reason: '$fixture would auto-add silently');
      });
    });
  });

  test('every candidate list scores deterministically', () {
    for (final fixture in candidateFixtures) {
      expect(rank(fixture.name).confidence, rank(fixture.name).confidence,
          reason: fixture.name);
    }
  });
}
