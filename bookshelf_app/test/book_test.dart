import 'package:bookshelf_app/models/book.dart';
import 'package:flutter_test/flutter_test.dart';

// A real thumbnail URL as the Google Books search endpoint returns it.
const _thumbnail = 'http://books.google.com/books/content'
    '?id=_zQsDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl'
    '&source=gbs_api';

void main() {
  group('googleCoverUrl', () {
    test('serves a 600px rendition instead of the 128px default', () {
      // Left as-is, imageLinks.thumbnail is 128px wide — narrower than a
      // library grid tile, and blurrier than the Open Library covers it
      // replaces.
      expect(Book.googleCoverUrl(_thumbnail), contains('&fife=w600'));
    });

    test('drops the fake page-curl overlay', () {
      expect(Book.googleCoverUrl(_thumbnail), isNot(contains('edge=curl')));
    });

    test('forces https', () {
      final url = Book.googleCoverUrl(_thumbnail)!;
      expect(url, startsWith('https://'));
      expect(url, isNot(contains('http://')));
    });

    test('keeps the volume identifier intact', () {
      expect(Book.googleCoverUrl(_thumbnail), contains('id=_zQsDwAAQBAJ'));
    });

    test('never stacks two widths', () {
      final once = Book.googleCoverUrl(_thumbnail)!;
      final twice = Book.googleCoverUrl(once)!;
      expect(twice, twice); // idempotent
      expect('&fife='.allMatches(twice).length, 1);
    });

    test('returns null when the volume has no image', () {
      expect(Book.googleCoverUrl(null), isNull);
      expect(Book.googleCoverUrl(''), isNull);
    });
  });

  group('identityKey', () {
    test('two editions of one book share a key', () {
      expect(Book.identityKey('The Overstory', 'Richard Powers'),
          Book.identityKey('the overstory', 'richard powers'));
    });

    test('a subtitle does not make it a different book', () {
      // Google returns "The Dream Hotel" and "The Dream Hotel: A Read with
      // Jenna Pick" as separate volumes of the same book.
      expect(Book.identityKey('The Dream Hotel: A Read with Jenna Pick', 'Laila Lalami'),
          Book.identityKey('The Dream Hotel', 'Laila Lalami'));
    });

    test('an edition parenthetical does not make it a different book', () {
      // Google returns the movie tie-in as its own volume with its own cover.
      // _coreTitle already ignores these when scoring, so identity must too, or
      // the runner-up is the book itself and the margin collapses again (#83).
      expect(Book.identityKey('Project Hail Mary (Movie Tie-In)', 'Andy Weir'),
          Book.identityKey('Project Hail Mary', 'Andy Weir'));
    });

    test('different books do not collide', () {
      expect(Book.identityKey('Pines', 'Blake Crouch'),
          isNot(Book.identityKey('Wayward', 'Blake Crouch')));
    });

    test('null without an author — two unattributed books are not the same', () {
      expect(Book.identityKey('Some Title', null), isNull);
      expect(Book.identityKey(null, 'Some Author'), isNull);
      expect(Book.identityKey('Some Title', '   '), isNull);
    });
  });

  test('fromGoogleBooksJson maps the fields the library screens read', () {
    final book = Book.fromGoogleBooksJson({
      'id': 'abc123',
      'volumeInfo': {
        'title': 'The Overstory',
        'authors': ['Richard Powers', 'Someone Else'],
        'description': 'A story about trees.',
        'categories': ['Fiction / Literary'],
        'pageCount': 502,
        'imageLinks': {'thumbnail': _thumbnail},
      },
    });

    expect(book.googleBooksId, 'abc123');
    expect(book.title, 'The Overstory');
    expect(book.author, 'Richard Powers');
    expect(book.description, 'A story about trees.');
    expect(book.genre, 'Fiction / Literary');
    expect(book.pageCount, 502);
    expect(book.coverUrl, contains('fife=w600'));
  });

  test('fromGoogleBooksJson survives a volume with almost nothing in it', () {
    // The API omits volumeInfo fields freely; a sparse record must not throw.
    final book = Book.fromGoogleBooksJson(
        {'id': 'x', 'volumeInfo': <String, dynamic>{}});
    expect(book.title, 'Unknown Title');
    expect(book.author, isNull);
    expect(book.coverUrl, isNull);
    expect(book.description, isNull);
  });
}
