import 'package:bookshelf_app/services/book_recognition_service.dart';
import 'package:bookshelf_app/services/books_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/ocr_fixtures.dart';

// Query-builder tests (#78). Every fixture is a verbatim ML Kit reading from a
// real photo in Margot's set, so these assert against what the device actually
// produces rather than against invented OCR. No network: the builder is a pure
// function, which is the whole reason it can be tested at this speed.
void main() {
  final service = BooksApiService();

  OcrResult ocrFor(String name) =>
      ocrFixtures.firstWhere((f) => f.name == name).ocr;
  String queryFor(String name) => service.buildSearchQuery(ocrFor(name));

  void expectQuery(
    String fixture, {
    List<String> withTokens = const [],
    List<String> without = const [],
  }) {
    final query = queryFor(fixture);
    final why = '$fixture query was "$query"';
    for (final token in withTokens) {
      expect(query, contains(token), reason: why);
    }
    for (final token in without) {
      expect(query, isNot(contains(token)), reason: why);
    }
  }

  group('cover furniture no longer outranks the title', () {
    test('Authority — vertical review band dropped', () {
      expectQuery('scaled_1500.heic',
          withTokens: ['Authority', 'VanderMeer'],
          without: ['SCARY', 'ANNIVERSARY', 'SOUTHERN REACH']);
    });

    test('The Overstory — bestseller band and digit-fused garbage dropped', () {
      expectQuery('scaled_1496.heic',
          withTokens: ['Overstory', 'Richard', 'PoWers'],
          without: ['20SE', 'TSELLER', 'PULITZER']);
    });

    test('Unbecoming — one-word title outscores the blurb', () {
      expectQuery('scaled_1453.jpg', withTokens: ['Unbecoming', 'Bhagwati']);
    });

    test('I Cheerfully Refuse — split "NATIONAL BESTSELL ER" dropped', () {
      expectQuery('scaled_1497.heic', without: ['BESTSELL', 'SELL ER']);
    });

    test('The Cruel Prince — "#1 NEW YO" rank marker dropped', () {
      expectQuery('scaled_1934.jpg', without: ['#1', 'NEW YO']);
    });

    test('Monk & Robot — repeated spine text no longer fills the query', () {
      expectQuery('scaled_1498.heic', without: ['EMILY']);
    });
  });

  group('retries repair what filtering cannot', () {
    test('The Notebook — despaced retry rebuilds letter-spaced type', () {
      expect(service.despacedQuery(ocrFor('scaled_1452.jpg')),
          'NoTEBOOK Nicholas Sparks');
    });

    test('Transformed — clean duplicate beats the fragmented one', () {
      // OCR reads this cover twice: "TRAN SFOR MED" and an intact
      // "Transformed". Dedup must keep the intact reading, and the relaxed
      // retry must drop the marketing subtitle that outranks neither.
      expectQuery('scaled_1454.jpg',
          withTokens: ['Transformed'], without: ['TRAN SFOR']);
      expect(service.relaxedQuery(ocrFor('scaled_1454.jpg')),
          'Transformed REMI ADELEKE');
    });

    test('relaxing drops a whole line, never part of one', () {
      // The old word-count relaxation cut mid-line: "INVISIBLE CITIES ITALO
      // CALVINO" became "INVISIBLE CITIES ITALO", losing the surname that
      // identifies the author.
      expect(service.relaxedQuery(ocrFor('scaled_1459.heic')),
          'THE DREAM HOTEL');
    });

    test('nothing to relax when the query is already minimal', () {
      // Invisible Cities yields exactly two usable lines, so dropping one more
      // would leave a bare title — the retry correctly declines.
      expect(service.relaxedQuery(ocrFor('scaled_1458.heic')), isNull);
    });
  });

  group('screenshot chrome', () {
    test('LOTR — Goodreads nav and app UI dropped, title survives', () {
      expectQuery('scaled_1450.png',
          withTokens: ['TOLKIEN'],
          without: ['Goodreads', 'Share', 'Home', 'Notifications', 'J.RR.']);
    });

    test('Project Hail Mary — TikTok chrome and blurb marker dropped', () {
      expectQuery('scaled_1451.png',
          without: ['booktok', 'Add comment', 'AUTHOR OF']);
    });

    test('Pines — wikipedia domain line dropped', () {
      expectQuery('scaled_1460.png', without: ['en.wikipedia.org']);
    });
  });

  group('books that already worked must not regress', () {
    test('Castle', () {
      expect(queryFor('scaled_1457.heic'), 'CASTLE JOHN GOODALL');
    });

    test('A House With Good Bones', () {
      expectQuery('scaled_1495.heic',
          withTokens: ['KINGFISHER', 'HOUSE'], without: ['GALLEBy', 'MOIin']);
    });

    test('A Year of Ravens', () {
      expectQuery('scaled_1494.heic', withTokens: ['RAVENS', 'Kate Quinn']);
    });

    test('Fair Play', () {
      expectQuery('scaled_1461.png', withTokens: ['FAIR PLAY']);
    });

    test('The Dream Hotel — book-club badge dropped, author gained', () {
      expectQuery('scaled_1459.heic',
          withTokens: ['DREAM', 'HOTEL', 'LALAMI'],
          without: ['READ WITH', 'JENNA']);
    });

    test('Invisible Cities — neighbouring spines and credits dropped', () {
      expect(queryFor('scaled_1458.heic'), 'INVISIBLE CITIES ITALO CALVINO');
    });
  });

  test('every fixture builds the same query twice', () {
    // Most cover lines are ALL CAPS and score identically, so ties are the norm
    // and an unstable sort would silently vary the query between runs.
    for (final fixture in ocrFixtures) {
      expect(service.buildSearchQuery(fixture.ocr),
          service.buildSearchQuery(fixture.ocr),
          reason: fixture.name);
    }
  });

  test('no query is empty', () {
    for (final fixture in ocrFixtures) {
      expect(service.buildSearchQuery(fixture.ocr), isNotEmpty,
          reason: fixture.name);
    }
  });

  test('joining lines keeps the space between them', () {
    // Collapsing ran on the joined string, so a line starting "A SAGA…" glued
    // its "A" onto the previous line: "THE HOUSE OF" + "A SAGA" came out as
    // "THE HOUSE OFA SAGA".
    expect(queryFor('scaled_1456.heic'), contains('OF A SAGA'));
  });
}
